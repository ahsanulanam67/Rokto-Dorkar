from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.db import transaction
from django.utils import timezone
from rest_framework import serializers
from rest_framework.exceptions import AuthenticationFailed
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from Accounts.services import OTPError, issue_email_otp, verify_email_otp
from Blood_app.country import country_data
from Blood_app.duplicates import create_duplicate_alerts
from Blood_app.models import BloodRequest, DuplicateDonorAlert, Person
from Blood_app.phones import is_valid_bangladesh_phone, normalize_phone

User = get_user_model()
BLOOD_GROUPS = ("A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-")


def validate_location(attrs, instance=None):
    division = attrs.get("division", getattr(instance, "division", None))
    district = attrs.get("district", getattr(instance, "district", None))
    subdistrict = attrs.get("subdistrict", getattr(instance, "subdistrict", None))
    districts = country_data.get(division)
    if not districts or district not in districts:
        raise serializers.ValidationError({"district": "Choose a valid district for this division."})
    if subdistrict not in districts[district]:
        raise serializers.ValidationError({"subdistrict": "Choose a valid subdistrict for this district."})
    return attrs


class NullableDateField(serializers.DateField):
    def to_internal_value(self, value):
        if value in ("", None):
            return None
        return super().to_internal_value(value)


class RegistrationRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()
    phone_number = serializers.CharField(max_length=50)
    name = serializers.CharField(max_length=100)
    gender = serializers.ChoiceField(choices=Person.Gender.choices)
    blood_group = serializers.ChoiceField(choices=BLOOD_GROUPS)
    division = serializers.CharField(max_length=100)
    district = serializers.CharField(max_length=100)
    subdistrict = serializers.CharField(max_length=100)
    password = serializers.CharField(write_only=True)
    confirm_password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        if attrs["password"] != attrs.pop("confirm_password"):
            raise serializers.ValidationError({"confirm_password": "Passwords do not match."})
        attrs["email"] = attrs["email"].lower()
        attrs["phone_number"] = normalize_phone(attrs["phone_number"])
        if not is_valid_bangladesh_phone(attrs["phone_number"]):
            raise serializers.ValidationError({"phone_number": "Enter a valid Bangladesh mobile number."})
        validate_location(attrs)
        validate_password(attrs["password"])
        existing = User.objects.filter(email__iexact=attrs["email"]).first()
        if existing and existing.email_verified:
            raise serializers.ValidationError({"email": "An account with this email already exists."})
        phone = attrs["phone_number"]
        if phone and User.objects.filter(phone_number=phone).exclude(pk=getattr(existing, "pk", None)).exists():
            raise serializers.ValidationError({"phone_number": "This phone number is already in use."})
        return attrs

    def create(self, validated_data):
        email = validated_data["email"]
        password = validated_data["password"]
        phone_number = validated_data["phone_number"]
        profile_values = {
            key: validated_data[key]
            for key in ("name", "gender", "blood_group", "division", "district", "subdistrict")
        }
        profile_values.update({"mobile_number": phone_number, "is_available": False})
        with transaction.atomic():
            user = User.objects.filter(email__iexact=email).first()
            if user is None:
                user = User.objects.create_user(
                    email=email,
                    phone_number=phone_number,
                    password=password,
                    is_active=False,
                    email_verified=False,
                )
            else:
                user.phone_number = phone_number
                user.is_active = False
                user.set_password(password)
                user.save(update_fields=("phone_number", "is_active", "password"))
            Person.objects.update_or_create(user=user, defaults=profile_values)
        debug_otp = issue_email_otp(user)
        self.debug_otp = debug_otp
        return user


class RegistrationVerifySerializer(serializers.Serializer):
    email = serializers.EmailField()
    otp = serializers.RegexField(r"^\d{6}$")

    def validate(self, attrs):
        try:
            user = User.objects.get(email__iexact=attrs["email"])
        except User.DoesNotExist:
            raise serializers.ValidationError({"email": "No pending registration was found."})
        try:
            attrs["user"] = verify_email_otp(user, attrs["otp"])
            profile = Person.objects.filter(user=user).first()
            if profile:
                profile.is_available = True
                profile.save(update_fields=("is_available", "updated_at"))
                attrs["duplicate_alerts_created"] = create_duplicate_alerts(profile)
        except OTPError as exc:
            raise serializers.ValidationError({"otp": str(exc)}) from exc
        return attrs


class ResendOTPSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def validate_email(self, value):
        try:
            user = User.objects.get(email__iexact=value)
        except User.DoesNotExist:
            raise serializers.ValidationError("No pending registration was found.")
        if user.email_verified:
            raise serializers.ValidationError("This email is already verified.")
        self.user = user
        return value.lower()


class EmailTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token["email"] = user.email
        token["role"] = user.role
        return token

    def validate(self, attrs):
        email = attrs.get("email")
        if email:
            attrs["email"] = email.lower()
        candidate = User.objects.filter(email__iexact=email).first() if email else None
        if candidate and not candidate.email_verified:
            raise AuthenticationFailed("Verify your email before logging in.")
        data = super().validate(attrs)
        data["user"] = {
            "id": self.user.id,
            "email": self.user.email,
            "phone_number": self.user.phone_number,
            "role": self.user.role,
        }
        data["has_profile"] = Person.objects.filter(user=self.user, name__isnull=False).exists()
        return data


class PersonSerializer(serializers.ModelSerializer):
    lastdonate = NullableDateField(required=False, allow_null=True)
    email = serializers.EmailField(source="user.email", read_only=True)
    phone_number = serializers.CharField(source="user.phone_number", read_only=True)
    role = serializers.CharField(source="user.role", read_only=True)
    can_moderate = serializers.BooleanField(source="user.can_moderate", read_only=True)
    created_by_email = serializers.EmailField(source="created_by.email", read_only=True)
    has_account = serializers.SerializerMethodField()
    eligible_to_donate = serializers.BooleanField(read_only=True)
    next_available_date = serializers.DateField(read_only=True)
    distance_km = serializers.SerializerMethodField()

    class Meta:
        model = Person
        fields = (
            "id", "email", "phone_number", "role", "can_moderate", "created_by_email", "has_account",
            "name", "age", "gender", "mobile_number", "blood_group",
            "division", "district", "subdistrict",
            "lastdonate", "latitude", "longitude", "is_available",
            "eligible_to_donate", "next_available_date", "distance_km", "updated_at",
        )

    def validate_age(self, value):
        if value is not None and not 18 <= value <= 65:
            raise serializers.ValidationError("Donor age must be between 18 and 65.")
        return value

    def validate_blood_group(self, value):
        if value not in BLOOD_GROUPS:
            raise serializers.ValidationError("Choose a valid blood group.")
        return value

    def validate_mobile_number(self, value):
        value = normalize_phone(value)
        if not is_valid_bangladesh_phone(value):
            raise serializers.ValidationError("Enter a valid Bangladesh mobile number.")
        if self.instance and self.instance.user_id:
            exists = User.objects.filter(phone_number=value).exclude(pk=self.instance.user_id).exists()
            if exists:
                raise serializers.ValidationError("This phone number is already in use.")
        return value

    def validate_lastdonate(self, value):
        if value and value > timezone.localdate():
            raise serializers.ValidationError("Last donation cannot be in the future.")
        return value

    def validate(self, attrs):
        return validate_location(attrs, self.instance)

    def update(self, instance, validated_data):
        profile = super().update(instance, validated_data)
        if profile.user_id and "mobile_number" in validated_data:
            profile.user.phone_number = profile.mobile_number
            profile.user.save(update_fields=("phone_number",))
        return profile

    def get_distance_km(self, obj):
        value = getattr(obj, "distance_km", None)
        return round(value, 1) if value is not None else None

    def get_has_account(self, obj):
        return obj.user_id is not None


class ManualDonorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Person
        fields = (
            "id", "name", "age", "gender", "mobile_number", "blood_group",
            "division", "district", "subdistrict", "lastdonate", "is_available",
            "latitude", "longitude",
        )
        read_only_fields = ("id", "latitude", "longitude")
        extra_kwargs = {
            "name": {"required": True, "allow_null": False},
            "gender": {"required": True, "allow_null": False},
            "mobile_number": {"required": True, "allow_null": False},
            "blood_group": {"required": True, "allow_null": False},
            "division": {"required": True, "allow_null": False},
            "district": {"required": True, "allow_null": False},
            "subdistrict": {"required": True, "allow_null": False},
        }

    def validate_mobile_number(self, value):
        value = normalize_phone(value)
        if not is_valid_bangladesh_phone(value):
            raise serializers.ValidationError("Enter a valid Bangladesh mobile number.")
        return value

    def validate_age(self, value):
        if value is not None and not 18 <= value <= 65:
            raise serializers.ValidationError("Donor age must be between 18 and 65.")
        return value

    def validate_lastdonate(self, value):
        if value and value > timezone.localdate():
            raise serializers.ValidationError("Last donation cannot be in the future.")
        return value

    def validate_blood_group(self, value):
        if value not in BLOOD_GROUPS:
            raise serializers.ValidationError("Choose a valid blood group.")
        return value

    def validate(self, attrs):
        return validate_location(attrs)


class DuplicateDonorAlertSerializer(serializers.ModelSerializer):
    registered_donor = PersonSerializer(read_only=True)
    manual_donor = PersonSerializer(read_only=True)

    class Meta:
        model = DuplicateDonorAlert
        fields = (
            "id", "normalized_phone", "status", "created_at",
            "registered_donor", "manual_donor",
        )


class UserRoleSerializer(serializers.ModelSerializer):
    name = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ("id", "email", "phone_number", "name", "role", "email_verified", "is_active")

    def get_name(self, obj):
        profile = getattr(obj, "person", None)
        return profile.name if profile else None


class RoleUpdateSerializer(serializers.Serializer):
    role = serializers.ChoiceField(choices=("user", "moderator"))


class BloodRequestSerializer(serializers.ModelSerializer):
    is_owner = serializers.SerializerMethodField()
    can_moderate = serializers.SerializerMethodField()
    created_by_phone = serializers.CharField(source="created_by.phone_number", read_only=True)
    created_by_email = serializers.EmailField(source="created_by.email", read_only=True)

    class Meta:
        model = BloodRequest
        fields = "__all__"
        read_only_fields = ("created_by", "created_at", "updated_at")

    def get_is_owner(self, obj):
        request = self.context.get("request")
        return bool(request and request.user == obj.created_by)

    def get_can_moderate(self, obj):
        request = self.context.get("request")
        return bool(request and request.user.can_moderate)

    def validate_units(self, value):
        if value < 1 or value > 20:
            raise serializers.ValidationError("Units must be between 1 and 20.")
        return value

    def validate_contact_number(self, value):
        value = normalize_phone(value)
        if not is_valid_bangladesh_phone(value):
            raise serializers.ValidationError("Enter a valid Bangladesh mobile number.")
        return value

    def validate_needed_date(self, value):
        if value < timezone.localdate():
            raise serializers.ValidationError("The required date cannot be in the past.")
        return value

    def validate(self, attrs):
        return validate_location(attrs, self.instance)


class DonorAvailabilitySerializer(serializers.ModelSerializer):
    class Meta:
        model = Person
        fields = ("id", "is_available")
        read_only_fields = ("id",)

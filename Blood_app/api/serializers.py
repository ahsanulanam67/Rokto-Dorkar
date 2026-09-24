from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.db import transaction
from rest_framework import serializers
from rest_framework.exceptions import AuthenticationFailed
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from Accounts.services import OTPError, issue_email_otp, verify_email_otp
from Blood_app.models import BloodRequest, Person

User = get_user_model()


class NullableDateField(serializers.DateField):
    def to_internal_value(self, value):
        if value in ("", None):
            return None
        return super().to_internal_value(value)


class RegistrationRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()
    phone_number = serializers.CharField(max_length=50, required=False, allow_blank=True)
    password = serializers.CharField(write_only=True)
    confirm_password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        if attrs["password"] != attrs.pop("confirm_password"):
            raise serializers.ValidationError({"confirm_password": "Passwords do not match."})
        attrs["email"] = attrs["email"].lower()
        validate_password(attrs["password"])
        existing = User.objects.filter(email__iexact=attrs["email"]).first()
        if existing and existing.email_verified:
            raise serializers.ValidationError({"email": "An account with this email already exists."})
        phone = attrs.get("phone_number") or None
        if phone and User.objects.filter(phone_number=phone).exclude(pk=getattr(existing, "pk", None)).exists():
            raise serializers.ValidationError({"phone_number": "This phone number is already in use."})
        return attrs

    def create(self, validated_data):
        email = validated_data["email"]
        password = validated_data["password"]
        phone_number = validated_data.get("phone_number") or None
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
        debug_otp = issue_email_otp(user, enforce_cooldown=False)
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
    image_url = serializers.SerializerMethodField()
    eligible_to_donate = serializers.BooleanField(read_only=True)
    next_available_date = serializers.DateField(read_only=True)
    distance_km = serializers.SerializerMethodField()

    class Meta:
        model = Person
        fields = (
            "id", "email", "phone_number", "role", "can_moderate", "name", "age", "gender", "mobile_number", "blood_group",
            "division", "district", "subdistrict", "person_image", "image_url",
            "lastdonate", "latitude", "longitude", "is_available",
            "eligible_to_donate", "next_available_date", "distance_km", "updated_at",
        )
        extra_kwargs = {"person_image": {"write_only": True, "required": False}}

    def get_image_url(self, obj):
        if not obj.person_image:
            return None
        url = obj.person_image.url
        request = self.context.get("request")
        return request.build_absolute_uri(url) if request and url.startswith("/") else url

    def get_distance_km(self, obj):
        value = getattr(obj, "distance_km", None)
        return round(value, 1) if value is not None else None


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


class DonorAvailabilitySerializer(serializers.ModelSerializer):
    class Meta:
        model = Person
        fields = ("id", "is_available")
        read_only_fields = ("id",)

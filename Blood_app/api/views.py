from math import asin, cos, radians, sin, sqrt

import requests
from django.contrib.auth import get_user_model
from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, permissions, status, viewsets
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from Accounts.services import (
    OTPDeliveryError,
    OTPCooldownError,
    issue_email_otp,
    issue_password_reset_otp,
)
from Blood_app.country import country_data
from Blood_app.duplicates import create_duplicate_alerts
from Blood_app.models import BloodRequest, DuplicateDonorAlert, Person
from Blood_app.phones import normalize_phone
from .serializers import (
    BloodRequestSerializer,
    DonorAvailabilitySerializer,
    EmailTokenObtainPairSerializer,
    DuplicateDonorAlertSerializer,
    ManualDonorSerializer,
    PasswordResetConfirmSerializer,
    PasswordResetRequestSerializer,
    PersonSerializer,
    RegistrationRequestSerializer,
    RegistrationVerifySerializer,
    ResendOTPSerializer,
    RoleUpdateSerializer,
    UserRoleSerializer,
)

User = get_user_model()


def geocode(division, district, subdistrict):
    parts = [part for part in (subdistrict, district, division, "Bangladesh") if part and part.upper() != "ALL"]
    try:
        response = requests.get(
            "https://nominatim.openstreetmap.org/search",
            params={"q": ", ".join(parts), "format": "json", "limit": 1},
            headers={"User-Agent": "RoktoDorkar/2.0 (blood-donor-search)"},
            timeout=6,
        )
        response.raise_for_status()
        result = response.json()
        return (float(result[0]["lat"]), float(result[0]["lon"])) if result else (None, None)
    except (requests.RequestException, ValueError, KeyError, IndexError):
        return None, None


def haversine_km(lat1, lon1, lat2, lon2):
    lat1, lon1, lat2, lon2 = map(radians, (lat1, lon1, lat2, lon2))
    dlat, dlon = lat2 - lat1, lon2 - lon1
    value = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    return 6371.0 * 2 * asin(sqrt(value))


def auth_payload(user):
    refresh = RefreshToken.for_user(user)
    refresh["email"] = user.email
    refresh["role"] = user.role
    return {
        "refresh": str(refresh),
        "access": str(refresh.access_token),
        "user": {"id": user.id, "email": user.email, "phone_number": user.phone_number, "role": user.role},
        "has_profile": Person.objects.filter(user=user, name__isnull=False).exists(),
    }


class RegisterView(APIView):
    permission_classes = (permissions.AllowAny,)
    throttle_scope = "otp_send"

    def post(self, request):
        serializer = RegistrationRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            serializer.save()
        except OTPCooldownError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_429_TOO_MANY_REQUESTS)
        except OTPDeliveryError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        data = {"detail": "Verification code sent.", "email": serializer.validated_data["email"]}
        if getattr(serializer, "debug_otp", None):
            data["debug_otp"] = serializer.debug_otp
        return Response(data, status=status.HTTP_201_CREATED)


class VerifyRegistrationView(APIView):
    permission_classes = (permissions.AllowAny,)
    throttle_scope = "otp_verify"

    def post(self, request):
        serializer = RegistrationVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = auth_payload(serializer.validated_data["user"])
        duplicate_count = serializer.validated_data.get("duplicate_alerts_created", 0)
        if duplicate_count:
            data["notice"] = "A matching donor record was found. An administrator will review it."
        return Response(data)


class ResendOTPView(APIView):
    permission_classes = (permissions.AllowAny,)
    throttle_scope = "otp_send"

    def post(self, request):
        serializer = ResendOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            debug_otp = issue_email_otp(serializer.user)
        except OTPCooldownError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_429_TOO_MANY_REQUESTS)
        except OTPDeliveryError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        data = {"detail": "A new verification code was sent."}
        if debug_otp:
            data["debug_otp"] = debug_otp
        return Response(data)


class EmailTokenObtainPairView(TokenObtainPairView):
    serializer_class = EmailTokenObtainPairSerializer
    throttle_scope = "login"


class PasswordResetRequestView(APIView):
    permission_classes = (permissions.AllowAny,)
    throttle_scope = "otp_send"

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        debug_otp = None
        if serializer.user:
            try:
                debug_otp = issue_password_reset_otp(serializer.user)
            except OTPCooldownError as exc:
                return Response({"detail": str(exc)}, status=status.HTTP_429_TOO_MANY_REQUESTS)
            except OTPDeliveryError as exc:
                return Response({"detail": str(exc)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        data = {
            "detail": "If an active account exists for this email, a password reset code was sent."
        }
        if debug_otp:
            data["debug_otp"] = debug_otp
        return Response(data)


class PasswordResetConfirmView(APIView):
    permission_classes = (permissions.AllowAny,)
    throttle_scope = "otp_verify"

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({"detail": "Your password has been reset. You can now log in."})


class IsModerator(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.can_moderate)


class IsAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and (request.user.is_superuser or request.user.role == "admin")
        )


class DonorAvailabilityView(generics.UpdateAPIView):
    queryset = Person.objects.all()
    serializer_class = DonorAvailabilitySerializer
    permission_classes = (IsModerator,)
    http_method_names = ("patch", "options")


class ProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = PersonSerializer

    def get_object(self):
        profile, _ = Person.objects.get_or_create(user=self.request.user)
        return profile

    def perform_update(self, serializer):
        profile = serializer.save()
        if profile.latitude is None or profile.longitude is None:
            latitude, longitude = geocode(profile.division, profile.district, profile.subdistrict)
            if latitude is not None:
                profile.latitude, profile.longitude = latitude, longitude
                profile.save(update_fields=("latitude", "longitude", "updated_at"))


class DonorListView(generics.ListAPIView):
    serializer_class = PersonSerializer

    def get_queryset(self):
        params = self.request.query_params
        queryset = (
            Person.objects.exclude(name__isnull=True)
            .exclude(name="")
            .filter(Q(user__isnull=True) | Q(user__is_active=True))
            .select_related("user", "created_by")
        )
        blood_group = params.get("blood_group")
        if blood_group:
            queryset = queryset.filter(blood_group=blood_group)

        try:
            latitude, longitude = float(params["latitude"]), float(params["longitude"])
        except (KeyError, TypeError, ValueError):
            latitude = longitude = None

        # A radius search is purely geographic so it can cross upazila,
        # district, and division borders. Administrative filters are used only
        # when the caller has not supplied a position.
        if latitude is None or longitude is None:
            for field in ("division", "district", "subdistrict"):
                value = params.get(field)
                if value and value.upper() != "ALL":
                    queryset = queryset.filter(**{f"{field}__iexact": value})

        if params.get("eligible_only", "true").lower() != "false":
            cutoff = timezone.localdate() - timezone.timedelta(days=120)
            queryset = queryset.filter(is_available=True).filter(Q(lastdonate__isnull=True) | Q(lastdonate__lte=cutoff))

        donors = list(queryset.order_by("-updated_at")[:500])
        if latitude is not None and longitude is not None:
            try:
                radius = min(max(float(params.get("radius_km", 30)), 1), 200)
            except ValueError:
                radius = 30
            nearby = []
            for donor in donors:
                if donor.latitude is None or donor.longitude is None:
                    continue
                donor.distance_km = haversine_km(latitude, longitude, donor.latitude, donor.longitude)
                if donor.distance_km <= radius:
                    nearby.append(donor)
            donors = sorted(nearby, key=lambda donor: donor.distance_km)
        return donors[:200]


class ManualDonorCreateView(generics.CreateAPIView):
    serializer_class = ManualDonorSerializer
    permission_classes = (IsModerator,)

    def perform_create(self, serializer):
        donor = serializer.save(user=None, created_by=self.request.user)
        latitude, longitude = geocode(donor.division, donor.district, donor.subdistrict)
        if latitude is not None:
            donor.latitude, donor.longitude = latitude, longitude
            donor.save(update_fields=("latitude", "longitude", "updated_at"))

        phone = normalize_phone(donor.mobile_number)
        registered_donors = Person.objects.filter(
            user__isnull=False,
            user__is_active=True,
            mobile_number=phone,
        )
        for registered in registered_donors:
            create_duplicate_alerts(registered)


class UserListView(generics.ListAPIView):
    serializer_class = UserRoleSerializer
    permission_classes = (IsAdmin,)

    def get_queryset(self):
        queryset = User.objects.select_related("person").order_by("email")
        search = self.request.query_params.get("search", "").strip()
        if search:
            queryset = queryset.filter(Q(email__icontains=search) | Q(phone_number__icontains=search))
        return queryset


class UserRoleUpdateView(APIView):
    permission_classes = (IsAdmin,)

    def patch(self, request, pk):
        target = get_object_or_404(User, pk=pk)
        if target.is_superuser or target.role == "admin":
            return Response({"detail": "Administrator roles cannot be changed here."}, status=400)
        serializer = RoleUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        target.role = serializer.validated_data["role"]
        target.save(update_fields=("role",))
        return Response(UserRoleSerializer(target).data)


class UserDeleteView(APIView):
    permission_classes = (IsAdmin,)

    def delete(self, request, pk):
        target = get_object_or_404(User, pk=pk)
        if target.pk == request.user.pk:
            return Response({"detail": "You cannot delete your own account."}, status=400)
        if target.is_superuser or target.role == "admin":
            return Response({"detail": "Administrator accounts cannot be deleted here."}, status=400)
        target.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class AdminDonorListView(generics.ListAPIView):
    serializer_class = PersonSerializer
    permission_classes = (IsAdmin,)

    def get_queryset(self):
        return Person.objects.select_related("user", "created_by").order_by("name", "id")


class AdminDonorDeleteView(generics.DestroyAPIView):
    queryset = Person.objects.all()
    permission_classes = (IsAdmin,)
    http_method_names = ("delete", "options")


class DuplicateAlertListView(generics.ListAPIView):
    serializer_class = DuplicateDonorAlertSerializer
    permission_classes = (IsAdmin,)

    def get_queryset(self):
        return DuplicateDonorAlert.objects.filter(
            status=DuplicateDonorAlert.Status.PENDING,
        ).select_related("registered_donor__user", "manual_donor")


class DuplicateAlertResolveView(APIView):
    permission_classes = (IsAdmin,)

    def post(self, request, pk):
        alert = get_object_or_404(
            DuplicateDonorAlert,
            pk=pk,
            status=DuplicateDonorAlert.Status.PENDING,
        )
        resolution = request.data.get("resolution")
        if resolution == "delete_manual":
            manual_donor = alert.manual_donor
            alert.status = DuplicateDonorAlert.Status.RESOLVED
            if manual_donor:
                manual_donor.delete()
                alert.manual_donor = None
        elif resolution == "dismiss":
            alert.status = DuplicateDonorAlert.Status.DISMISSED
        else:
            return Response({"resolution": "Choose delete_manual or dismiss."}, status=400)
        alert.resolved_at = timezone.now()
        alert.resolved_by = request.user
        alert.save(update_fields=("manual_donor", "status", "resolved_at", "resolved_by"))
        return Response(DuplicateDonorAlertSerializer(alert, context={"request": request}).data)


class BloodRequestViewSet(viewsets.ModelViewSet):
    serializer_class = BloodRequestSerializer
    http_method_names = ("get", "post", "patch", "delete", "head", "options")

    def get_queryset(self):
        queryset = BloodRequest.objects.select_related("created_by")
        if self.request.query_params.get("mine") == "true":
            return queryset.filter(created_by=self.request.user)
        status_filter = self.request.query_params.get("status", BloodRequest.Status.OPEN)
        if status_filter != "all":
            queryset = queryset.filter(status=status_filter)
        blood_group = self.request.query_params.get("blood_group")
        return queryset.filter(blood_group=blood_group) if blood_group else queryset

    def perform_create(self, serializer):
        item = serializer.save(created_by=self.request.user)
        if item.latitude is None or item.longitude is None:
            latitude, longitude = geocode(item.division, item.district, item.subdistrict)
            if latitude is not None:
                item.latitude, item.longitude = latitude, longitude
                item.save(update_fields=("latitude", "longitude", "updated_at"))

    def _require_owner(self, instance):
        if instance.created_by != self.request.user and not self.request.user.can_moderate:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Only the request owner can change it.")

    def perform_update(self, serializer):
        self._require_owner(serializer.instance)
        serializer.save()

    def perform_destroy(self, instance):
        self._require_owner(instance)
        instance.delete()

    @action(detail=True, methods=("patch",))
    def status(self, request, pk=None):
        item = self.get_object()
        self._require_owner(item)
        next_status = request.data.get("status")
        if next_status not in BloodRequest.Status.values:
            return Response({"status": "Invalid status."}, status=400)
        item.status = next_status
        item.save(update_fields=("status", "updated_at"))
        return Response(self.get_serializer(item).data)


@api_view(("GET",))
@permission_classes((permissions.AllowAny,))
def locations_view(request):
    return Response(country_data)


@api_view(("GET",))
@permission_classes((permissions.AllowAny,))
def health_view(request):
    return Response({"status": "ok"}, status=status.HTTP_200_OK)

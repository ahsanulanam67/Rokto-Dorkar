from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView, TokenVerifyView
from .views import (
    BloodRequestViewSet,
    DonorAvailabilityView,
    DonorListView,
    EmailTokenObtainPairView,
    ProfileView,
    RegisterView,
    ResendOTPView,
    VerifyRegistrationView,
    health_view,
    locations_view,
)

router = DefaultRouter()
router.register("requests", BloodRequestViewSet, basename="blood-request")

urlpatterns = [
    path("health/", health_view, name="api-health"),
    path("auth/register/", RegisterView.as_view(), name="api-register"),
    path("auth/register/verify/", VerifyRegistrationView.as_view(), name="api-register-verify"),
    path("auth/register/resend/", ResendOTPView.as_view(), name="api-register-resend"),
    path("auth/login/", EmailTokenObtainPairView.as_view(), name="api-login"),
    path("auth/refresh/", TokenRefreshView.as_view(), name="api-token-refresh"),
    path("auth/verify/", TokenVerifyView.as_view(), name="api-token-verify"),
    path("profile/", ProfileView.as_view(), name="api-profile"),
    path("donors/", DonorListView.as_view(), name="api-donors"),
    path("donors/<int:pk>/availability/", DonorAvailabilityView.as_view(), name="api-donor-availability"),
    path("locations/", locations_view, name="api-locations"),
    path("", include(router.urls)),
]

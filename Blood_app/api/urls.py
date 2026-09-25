from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView, TokenVerifyView
from .views import (
    AdminDonorDeleteView,
    AdminDonorListView,
    BloodRequestViewSet,
    DonorAvailabilityView,
    DonorListView,
    DuplicateAlertListView,
    DuplicateAlertResolveView,
    EmailTokenObtainPairView,
    ProfileView,
    ManualDonorCreateView,
    RegisterView,
    ResendOTPView,
    VerifyRegistrationView,
    UserListView,
    UserDeleteView,
    UserRoleUpdateView,
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
    path("moderation/donors/", ManualDonorCreateView.as_view(), name="api-manual-donor-create"),
    path("admin/users/", UserListView.as_view(), name="api-admin-users"),
    path("admin/users/<int:pk>/", UserDeleteView.as_view(), name="api-admin-user-delete"),
    path("admin/users/<int:pk>/role/", UserRoleUpdateView.as_view(), name="api-admin-user-role"),
    path("admin/donors/", AdminDonorListView.as_view(), name="api-admin-donors"),
    path("admin/donors/<int:pk>/", AdminDonorDeleteView.as_view(), name="api-admin-donor-delete"),
    path("admin/duplicates/", DuplicateAlertListView.as_view(), name="api-admin-duplicates"),
    path("admin/duplicates/<int:pk>/resolve/", DuplicateAlertResolveView.as_view(), name="api-admin-duplicate-resolve"),
    path("locations/", locations_view, name="api-locations"),
    path("", include(router.urls)),
]

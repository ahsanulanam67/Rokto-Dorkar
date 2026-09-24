from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import CustomUser, EmailVerificationOTP


@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    model = CustomUser
    ordering = ("email",)
    list_display = ("email", "phone_number", "role", "email_verified", "is_active", "is_staff")
    list_filter = ("role", "email_verified", "is_active", "is_staff")
    search_fields = ("email", "phone_number")
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Contact", {"fields": ("phone_number", "first_name", "last_name")}),
        ("Access", {"fields": ("role", "email_verified", "is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Dates", {"fields": ("last_login", "date_joined")}),
    )
    add_fieldsets = (
        (None, {"classes": ("wide",), "fields": ("email", "phone_number", "password1", "password2", "role", "email_verified", "is_active", "is_staff")}),
    )


@admin.register(EmailVerificationOTP)
class EmailVerificationOTPAdmin(admin.ModelAdmin):
    list_display = ("user", "expires_at", "last_sent_at", "attempts")
    readonly_fields = ("code_hash",)

from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils import timezone
from .manager import UserManager


class CustomUser(AbstractUser):
    class Role(models.TextChoices):
        USER = "user", "User"
        MODERATOR = "moderator", "Moderator"
        ADMIN = "admin", "Admin"

    username = None
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=50, unique=True, null=True, blank=True)
    role = models.CharField(max_length=12, choices=Role.choices, default=Role.USER)
    email_verified = models.BooleanField(default=False)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []
    objects = UserManager()

    @property
    def can_moderate(self):
        return self.is_superuser or self.role in {self.Role.MODERATOR, self.Role.ADMIN}

    def __str__(self):
        return self.email


class EmailVerificationOTP(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name="verification_otp")
    code_hash = models.CharField(max_length=128)
    expires_at = models.DateTimeField()
    last_sent_at = models.DateTimeField(default=timezone.now)
    attempts = models.PositiveSmallIntegerField(default=0)

    def __str__(self):
        return f"Email verification for {self.user.email}"

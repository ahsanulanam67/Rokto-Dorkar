import os

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = "Create the deployment superuser from environment variables when absent."

    def handle(self, *args, **options):
        email = os.getenv("SUPERUSER_EMAIL", "").strip().lower()
        password = os.getenv("SUPERUSER_PASSWORD", "")
        legacy_username = os.getenv("SUPERUSER_USERNAME", "").strip()
        if not email:
            self.stdout.write("SUPERUSER_EMAIL is not set; skipping admin bootstrap.")
            return
        if not password:
            raise CommandError("SUPERUSER_PASSWORD must be set when SUPERUSER_EMAIL is configured.")

        User = get_user_model()
        user, created = User.objects.get_or_create(email=email)
        changed = []
        for field, value in {
            "is_active": True,
            "is_staff": True,
            "is_superuser": True,
            "email_verified": True,
            "role": "admin",
        }.items():
            if getattr(user, field) != value:
                setattr(user, field, value)
                changed.append(field)
        if not user.phone_number and legacy_username and "@" not in legacy_username:
            user.phone_number = legacy_username
            changed.append("phone_number")
        if created:
            user.set_password(password)
            changed.append("password")
        if changed:
            user.save(update_fields=changed)
        self.stdout.write(self.style.SUCCESS(f"Admin account ready: {email}"))

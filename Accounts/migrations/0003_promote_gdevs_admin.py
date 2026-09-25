from django.db import migrations


ADMIN_EMAIL = "itsrough3825@gmail.com"


def promote_admin(apps, schema_editor):
    User = apps.get_model("Accounts", "CustomUser")
    user, _ = User.objects.get_or_create(
        email=ADMIN_EMAIL,
        defaults={
            "password": "!",
            "is_active": False,
            "email_verified": False,
        },
    )
    user.role = "admin"
    user.is_staff = True
    user.is_superuser = True
    user.save(update_fields=("role", "is_staff", "is_superuser"))


class Migration(migrations.Migration):
    dependencies = [("Accounts", "0002_email_auth_roles_and_otp")]

    operations = [
        migrations.RunPython(promote_admin, migrations.RunPython.noop),
    ]

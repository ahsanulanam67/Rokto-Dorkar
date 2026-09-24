from django.db import migrations, models
import django.db.models.deletion
import django.utils.timezone


def prepare_legacy_emails(apps, schema_editor):
    User = apps.get_model("Accounts", "CustomUser")
    for user in User.objects.all():
        if not user.email:
            phone = "".join(character for character in (user.phone_number or "") if character.isdigit())
            user.email = f"legacy-{phone or user.pk}-{user.pk}@invalid.local"
        user.email_verified = True
        if user.is_superuser:
            user.role = "admin"
        elif user.is_staff:
            user.role = "moderator"
        user.save(update_fields=("email", "email_verified", "role"))


class Migration(migrations.Migration):
    dependencies = [("Accounts", "0001_initial")]

    operations = [
        migrations.AddField(
            model_name="customuser",
            name="email_verified",
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name="customuser",
            name="role",
            field=models.CharField(
                choices=[("user", "User"), ("moderator", "Moderator"), ("admin", "Admin")],
                default="user",
                max_length=12,
            ),
        ),
        migrations.RunPython(prepare_legacy_emails, migrations.RunPython.noop),
        migrations.AlterField(
            model_name="customuser",
            name="email",
            field=models.EmailField(max_length=254, unique=True),
        ),
        migrations.AlterField(
            model_name="customuser",
            name="phone_number",
            field=models.CharField(blank=True, max_length=50, null=True, unique=True),
        ),
        migrations.CreateModel(
            name="EmailVerificationOTP",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("code_hash", models.CharField(max_length=128)),
                ("expires_at", models.DateTimeField()),
                ("last_sent_at", models.DateTimeField(default=django.utils.timezone.now)),
                ("attempts", models.PositiveSmallIntegerField(default=0)),
                ("user", models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name="verification_otp", to="Accounts.customuser")),
            ],
        ),
    ]

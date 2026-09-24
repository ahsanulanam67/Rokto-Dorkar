from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [
        ("Blood_app", "0011_person_latitude_person_longitude"),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AddField(model_name="person", name="is_available", field=models.BooleanField(default=True)),
        migrations.AddField(model_name="person", name="updated_at", field=models.DateTimeField(auto_now=True)),
        migrations.CreateModel(
            name="BloodRequest",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("patient_name", models.CharField(max_length=100)),
                ("blood_group", models.CharField(max_length=3)),
                ("hospital", models.CharField(max_length=180)),
                ("division", models.CharField(max_length=100)),
                ("district", models.CharField(max_length=100)),
                ("subdistrict", models.CharField(max_length=100)),
                ("contact_number", models.CharField(max_length=50)),
                ("needed_date", models.DateField()),
                ("units", models.PositiveSmallIntegerField(default=1)),
                ("notes", models.TextField(blank=True)),
                ("latitude", models.FloatField(blank=True, null=True)),
                ("longitude", models.FloatField(blank=True, null=True)),
                ("status", models.CharField(choices=[("open", "Open"), ("fulfilled", "Fulfilled"), ("cancelled", "Cancelled")], default="open", max_length=12)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("created_by", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="blood_requests", to=settings.AUTH_USER_MODEL)),
            ],
            options={"ordering": ["-created_at"]},
        ),
    ]

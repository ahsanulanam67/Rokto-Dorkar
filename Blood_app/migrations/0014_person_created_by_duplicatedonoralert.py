import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("Blood_app", "0013_person_gender"),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AddField(
            model_name="person",
            name="created_by",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="manually_added_donors",
                to=settings.AUTH_USER_MODEL,
            ),
        ),
        migrations.CreateModel(
            name="DuplicateDonorAlert",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("normalized_phone", models.CharField(db_index=True, max_length=20)),
                ("status", models.CharField(choices=[("pending", "Pending review"), ("resolved", "Manual donor deleted"), ("dismissed", "Not a duplicate")], default="pending", max_length=12)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("resolved_at", models.DateTimeField(blank=True, null=True)),
                ("manual_donor", models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="duplicate_matches", to="Blood_app.person")),
                ("registered_donor", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="duplicate_alerts", to="Blood_app.person")),
                ("resolved_by", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="resolved_duplicate_alerts", to=settings.AUTH_USER_MODEL)),
            ],
            options={"ordering": ("-created_at",)},
        ),
        migrations.AddConstraint(
            model_name="duplicatedonoralert",
            constraint=models.UniqueConstraint(fields=("registered_donor", "manual_donor"), name="unique_registered_manual_duplicate"),
        ),
    ]

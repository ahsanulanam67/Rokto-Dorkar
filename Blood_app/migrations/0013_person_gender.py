from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [("Blood_app", "0012_person_availability_and_blood_request")]

    operations = [
        migrations.AddField(
            model_name="person",
            name="gender",
            field=models.CharField(
                blank=True,
                choices=[
                    ("male", "Male"),
                    ("female", "Female"),
                    ("other", "Other / prefer not to say"),
                ],
                max_length=10,
                null=True,
            ),
        ),
    ]

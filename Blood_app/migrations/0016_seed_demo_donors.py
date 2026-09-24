from datetime import timedelta

from django.db import migrations
from django.utils import timezone


DEMO_DONORS = (
    {
        "name": "Demo Rahim Ahmed",
        "age": 28,
        "gender": "male",
        "mobile_number": "01000000001",
        "blood_group": "O+",
        "division": "Dhaka",
        "district": "Dhaka",
        "subdistrict": "Savar",
        "latitude": 23.8583,
        "longitude": 90.2667,
        "last_donated_days_ago": 154,
        "is_available": True,
    },
    {
        "name": "Demo Nusrat Jahan",
        "age": 24,
        "gender": "female",
        "mobile_number": "01000000002",
        "blood_group": "A-",
        "division": "Chattogram",
        "district": "Cumilla",
        "subdistrict": "Cumilla Adarsha Sadar",
        "latitude": 23.4607,
        "longitude": 91.1809,
        "last_donated_days_ago": None,
        "is_available": True,
    },
    {
        "name": "Demo Arif Hasan",
        "age": 31,
        "gender": "male",
        "mobile_number": "01000000003",
        "blood_group": "B+",
        "division": "Rajshahi",
        "district": "Rajshahi",
        "subdistrict": "Paba",
        "latitude": 24.3745,
        "longitude": 88.6042,
        "last_donated_days_ago": 201,
        "is_available": True,
    },
    {
        "name": "Demo Tania Akter",
        "age": 27,
        "gender": "female",
        "mobile_number": "01000000004",
        "blood_group": "AB+",
        "division": "Khulna",
        "district": "Khulna",
        "subdistrict": "Rupsha",
        "latitude": 22.8174,
        "longitude": 89.6441,
        "last_donated_days_ago": None,
        "is_available": True,
    },
    {
        "name": "Demo Samiul Islam",
        "age": 35,
        "gender": "male",
        "mobile_number": "01000000005",
        "blood_group": "O-",
        "division": "Sylhet",
        "district": "Sylhet",
        "subdistrict": "Sylhet Sadar",
        "latitude": 24.8949,
        "longitude": 91.8687,
        "last_donated_days_ago": 132,
        "is_available": True,
    },
    {
        "name": "Demo Farzana Yasmin",
        "age": 29,
        "gender": "female",
        "mobile_number": "01000000006",
        "blood_group": "A+",
        "division": "Dhaka",
        "district": "Tangail",
        "subdistrict": "Tangail Sadar",
        "latitude": 24.2513,
        "longitude": 89.9167,
        "last_donated_days_ago": 180,
        "is_available": True,
    },
    {
        "name": "Demo Mahmud Khan",
        "age": 33,
        "gender": "male",
        "mobile_number": "01000000007",
        "blood_group": "B-",
        "division": "Rangpur",
        "district": "Rangpur",
        "subdistrict": "Rangpur Sadar",
        "latitude": 25.7439,
        "longitude": 89.2752,
        "last_donated_days_ago": None,
        "is_available": True,
    },
    {
        "name": "Demo Rupa Das",
        "age": 26,
        "gender": "female",
        "mobile_number": "01000000008",
        "blood_group": "AB-",
        "division": "Barishal",
        "district": "Barishal",
        "subdistrict": "Barishal Sadar",
        "latitude": 22.7010,
        "longitude": 90.3535,
        "last_donated_days_ago": 145,
        "is_available": True,
    },
    {
        "name": "Demo Imran Hossain",
        "age": 22,
        "gender": "male",
        "mobile_number": "01000000009",
        "blood_group": "O+",
        "division": "Mymensingh",
        "district": "Mymensingh",
        "subdistrict": "Mymensingh Sadar",
        "latitude": 24.7471,
        "longitude": 90.4203,
        "last_donated_days_ago": 35,
        "is_available": True,
    },
    {
        "name": "Demo Sadia Rahman",
        "age": 30,
        "gender": "female",
        "mobile_number": "01000000010",
        "blood_group": "B+",
        "division": "Chattogram",
        "district": "Cox's Bazar",
        "subdistrict": "Cox's Bazar Sadar",
        "latitude": 21.4272,
        "longitude": 92.0058,
        "last_donated_days_ago": 170,
        "is_available": False,
    },
)


def seed_demo_donors(apps, schema_editor):
    Person = apps.get_model("Blood_app", "Person")
    today = timezone.localdate()
    for donor in DEMO_DONORS:
        values = donor.copy()
        days = values.pop("last_donated_days_ago")
        values["lastdonate"] = today - timedelta(days=days) if days else None
        existing = Person.objects.filter(
            user__isnull=True,
            mobile_number=values["mobile_number"],
        ).first()
        if existing is None:
            Person.objects.create(**values)


def remove_demo_donors(apps, schema_editor):
    Person = apps.get_model("Blood_app", "Person")
    phones = [donor["mobile_number"] for donor in DEMO_DONORS]
    Person.objects.filter(
        user__isnull=True,
        name__startswith="Demo ",
        mobile_number__in=phones,
    ).delete()


class Migration(migrations.Migration):
    dependencies = [("Blood_app", "0015_normalize_bangladesh_locations")]

    operations = [migrations.RunPython(seed_demo_donors, remove_demo_donors)]

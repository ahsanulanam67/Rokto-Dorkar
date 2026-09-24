from django.db import migrations


DIVISION_RENAMES = {
    "Barisal": "Barishal",
}

DISTRICT_RENAMES = {
    "Barisal": "Barishal",
    "Bogra": "Bogura",
    "Chapai Nawabganj": "Chapainawabganj",
    "Jessore": "Jashore",
    "Jhalokathi": "Jhalakathi",
    "Khagrachari": "Khagrachhari",
    "Khagrachari ": "Khagrachhari",
}

SUBDISTRICT_RENAMES = {
    "Barhatta Upazila": "Barhatta",
    "Charfasson": "Char Fasson",
    "Companyganj": "Companiganj",
    "Cumilla Shadar Dakkhin": "Cumilla Sadar Dakshin",
    "Durgapur Upazila": "Durgapur",
    "Gangachara": "Gangachhara",
    "Gournadi": "Gaurnadi",
    "Harinakundu": "Harinakunda",
    "Jhalokati Sadar": "Jhalakathi Sadar",
    "Khaliajuri Upazila": "Khaliajuri",
    "Khagrachari": "Khagrachhari Sadar",
    "kamalnagar": "Kamalnagar",
    "Mohalchari": "Mahalchhari",
    "Monohorganj": "Monoharganj",
    "Naniarchar": "Naniyachar",
    "Netrokona": "Netrokona Sadar",
    "Panchari": "Panchhari",
    "Pirgacha": "Pirgachha",
    "Ramgor": "Ramgarh",
    "Shaistaganj": "Shayestaganj",
    "Swarupkathi": "Nesarabad (Swarupkathi)",
    "Ullapara": "Ullahpara",
    "Zianagar": "Indurkani",
}


def normalize_locations(apps, schema_editor):
    Person = apps.get_model("Blood_app", "Person")
    for old, new in DIVISION_RENAMES.items():
        Person.objects.filter(division=old).update(division=new)
    for old, new in DISTRICT_RENAMES.items():
        Person.objects.filter(district=old).update(district=new)
    for old, new in SUBDISTRICT_RENAMES.items():
        Person.objects.filter(subdistrict=old).update(subdistrict=new)


class Migration(migrations.Migration):
    dependencies = [("Blood_app", "0014_person_created_by_duplicatedonoralert")]

    operations = [migrations.RunPython(normalize_locations, migrations.RunPython.noop)]

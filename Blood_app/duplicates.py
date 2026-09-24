from .models import DuplicateDonorAlert, Person
from .phones import normalize_phone


def create_duplicate_alerts(registered_donor):
    phone = normalize_phone(registered_donor.mobile_number)
    if not phone:
        return 0

    created = 0
    manual_donors = Person.objects.filter(user__isnull=True).exclude(mobile_number__isnull=True)
    for manual_donor in manual_donors:
        if normalize_phone(manual_donor.mobile_number) != phone:
            continue
        _, was_created = DuplicateDonorAlert.objects.get_or_create(
            registered_donor=registered_donor,
            manual_donor=manual_donor,
            defaults={"normalized_phone": phone},
        )
        created += int(was_created)
    return created

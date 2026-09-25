from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta

from .phones import normalize_phone

User = get_user_model()
# Create your models here.

class Person(models.Model):
    class Gender(models.TextChoices):
        MALE = "male", "Male"
        FEMALE = "female", "Female"
        OTHER = "other", "Other / prefer not to say"

    
    user = models.OneToOneField(User, on_delete=models.CASCADE,null=True,blank=True)
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="manually_added_donors",
    )
    name = models.CharField(null=True, max_length=100)
    age = models.IntegerField(null=True) 
    gender = models.CharField(max_length=10, choices=Gender.choices, null=True, blank=True)
    mobile_number = models.CharField(null=True, max_length=100, db_index=True)
    blood_group = models.CharField(null=True,max_length=10)
    division  = models.CharField(null=True,max_length=100)
    district = models.CharField(null=True,max_length=100)
    subdistrict = models.CharField(null=True,max_length=100)
    person_image = models.ImageField(null= True,upload_to='images/')
    lastdonate = models.DateField(null=True)
    longitude = models.FloatField(null=True, blank=True)
    latitude = models.FloatField(null=True, blank=True)
    is_available = models.BooleanField(default=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=("blood_group",), name="donor_blood_idx"),
            models.Index(
                fields=("division", "district", "subdistrict"),
                name="donor_location_idx",
            ),
            models.Index(
                fields=("is_available", "lastdonate"),
                name="donor_eligible_idx",
            ),
            models.Index(fields=("-updated_at",), name="donor_updated_idx"),
        ]

    def save(self, *args, **kwargs):
        normalized_phone = normalize_phone(self.mobile_number)
        if normalized_phone != self.mobile_number:
            self.mobile_number = normalized_phone or None
            update_fields = kwargs.get("update_fields")
            if update_fields is not None:
                kwargs["update_fields"] = set(update_fields) | {"mobile_number"}
        super().save(*args, **kwargs)

    @property
    def eligible_to_donate(self):
        if not self.is_available:
            return False
        return self.lastdonate is None or self.lastdonate <= timezone.localdate() - timedelta(days=120)

    @property
    def next_available_date(self):
        return self.lastdonate + timedelta(days=120) if self.lastdonate else None

    def __str__(self):
        if self.name:
            return self.name
        return self.user.phone_number if self.user else f"Donor {self.pk}"


class DuplicateDonorAlert(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending review"
        RESOLVED = "resolved", "Manual donor deleted"
        DISMISSED = "dismissed", "Not a duplicate"

    registered_donor = models.ForeignKey(
        Person,
        on_delete=models.CASCADE,
        related_name="duplicate_alerts",
    )
    manual_donor = models.ForeignKey(
        Person,
        on_delete=models.SET_NULL,
        null=True,
        related_name="duplicate_matches",
    )
    normalized_phone = models.CharField(max_length=20, db_index=True)
    status = models.CharField(max_length=12, choices=Status.choices, default=Status.PENDING)
    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    resolved_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="resolved_duplicate_alerts",
    )

    class Meta:
        ordering = ("-created_at",)
        indexes = [
            models.Index(
                fields=("status", "-created_at"),
                name="duplicate_status_idx",
            ),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=("registered_donor", "manual_donor"),
                name="unique_registered_manual_duplicate",
            )
        ]

    def __str__(self):
        return f"Duplicate phone {self.normalized_phone}"


class BloodRequest(models.Model):
    class Status(models.TextChoices):
        OPEN = "open", "Open"
        FULFILLED = "fulfilled", "Fulfilled"
        CANCELLED = "cancelled", "Cancelled"

    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name="blood_requests")
    patient_name = models.CharField(max_length=100)
    blood_group = models.CharField(max_length=3)
    hospital = models.CharField(max_length=180)
    division = models.CharField(max_length=100)
    district = models.CharField(max_length=100)
    subdistrict = models.CharField(max_length=100)
    contact_number = models.CharField(max_length=50)
    needed_date = models.DateField()
    units = models.PositiveSmallIntegerField(default=1)
    notes = models.TextField(blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    status = models.CharField(max_length=12, choices=Status.choices, default=Status.OPEN)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(
                fields=("status", "blood_group", "-created_at"),
                name="request_lookup_idx",
            ),
        ]

    def __str__(self):
        return f"{self.blood_group} for {self.patient_name}"

from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import override_settings
from django.utils import timezone
from rest_framework.test import APITestCase

from Blood_app.models import BloodRequest, Person


class ApiTests(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            email="member@example.com", phone_number="01700000000",
            password="StrongPass!42", email_verified=True,
        )
        response = self.client.post("/api/v1/auth/login/", {"email": "member@example.com", "password": "StrongPass!42"})
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {response.data['access']}")

    @override_settings(DEBUG=True, BREVO_API_KEY="")
    def test_email_otp_registration(self):
        self.client.credentials()
        response = self.client.post(
            "/api/v1/auth/register/",
            {
                "email": "new@example.com",
                "password": "AnotherStrong!42", "confirm_password": "AnotherStrong!42",
            },
        )
        self.assertEqual(response.status_code, 201)
        self.assertIn("debug_otp", response.data)
        user = get_user_model().objects.get(email="new@example.com")
        self.assertFalse(user.is_active)
        self.assertIsNone(user.phone_number)

        response = self.client.post(
            "/api/v1/auth/register/verify/",
            {"email": "new@example.com", "otp": response.data["debug_otp"]},
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn("access", response.data)
        user.refresh_from_db()
        self.assertTrue(user.email_verified)

    def test_profile_and_eligible_nearby_donor_search(self):
        donor_user = get_user_model().objects.create_user(
            email="donor@example.com", phone_number="01800000000",
            password="StrongPass!42", email_verified=True,
        )
        Person.objects.create(
            user=donor_user, name="Test Donor", age=28, gender="male", mobile_number="01800000000",
            blood_group="A+", division="Dhaka", district="Dhaka", subdistrict="Savar",
            lastdonate=timezone.localdate() - timedelta(days=121), latitude=23.8103, longitude=90.4125,
        )
        response = self.client.get("/api/v1/donors/", {"blood_group": "A+", "latitude": 23.81, "longitude": 90.41, "radius_km": 30})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["count"], 1)
        self.assertTrue(response.data["results"][0]["eligible_to_donate"])

    def test_profile_accepts_never_donated(self):
        response = self.client.patch(
            "/api/v1/profile/",
            {
                "name": "New Donor", "age": 25, "gender": "female", "mobile_number": "01700000000",
                "blood_group": "B+", "division": "Dhaka", "district": "Dhaka",
                "subdistrict": "Savar", "lastdonate": "", "is_available": True,
                "latitude": 23.8, "longitude": 90.4,
            },
            format="multipart",
        )
        self.assertEqual(response.status_code, 200)
        self.assertIsNone(response.data["lastdonate"])

    def test_request_lifecycle(self):
        payload = {
            "patient_name": "Patient", "blood_group": "O-", "hospital": "Medical College",
            "division": "Dhaka", "district": "Dhaka", "subdistrict": "Savar",
            "contact_number": "01700000000", "needed_date": str(timezone.localdate()),
            "units": 2, "notes": "Urgent", "latitude": 23.8, "longitude": 90.4,
        }
        response = self.client.post("/api/v1/requests/", payload)
        self.assertEqual(response.status_code, 201)
        request_id = response.data["id"]
        response = self.client.patch(f"/api/v1/requests/{request_id}/status/", {"status": "fulfilled"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(BloodRequest.objects.get(pk=request_id).status, "fulfilled")

    def test_moderator_can_hide_a_donor(self):
        moderator = get_user_model().objects.create_user(
            email="moderator@example.com", password="StrongPass!42",
            email_verified=True, role="moderator",
        )
        donor = Person.objects.create(user=self.user, name="Listed donor", is_available=True)
        response = self.client.post(
            "/api/v1/auth/login/",
            {"email": moderator.email, "password": "StrongPass!42"},
        )
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {response.data['access']}")
        response = self.client.patch(
            f"/api/v1/donors/{donor.pk}/availability/", {"is_available": False},
        )
        self.assertEqual(response.status_code, 200)
        donor.refresh_from_db()
        self.assertFalse(donor.is_available)

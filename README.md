# Rokto Dorkar

Rokto Dorkar is a full-stack blood donor network for Bangladesh. This repository contains:

- a Django REST API and Django admin;
- the original server-rendered Django website;
- a Flutter app for Android, iOS, and web;
- Neon PostgreSQL, Render, and Vercel deployment configuration.

## Features

- Email registration with required donor name, phone, blood group, gender, Bangladesh address, six-digit Brevo OTP verification, and JWT login
- User, moderator, and admin roles with server-enforced permissions
- Admin role management and moderator/admin creation of donors without accounts
- Phone-normalized duplicate alerts when a manually added donor later creates an account
- Admin review to delete the manual duplicate or dismiss an incorrect match
- Donor profile with gender-based avatar, contact details, blood group, and Bangladesh address
- Available/unavailable donor status
- Last-donation tracking and automatic 120-day eligibility calculation
- Donor search by blood group, division, district, and upazila
- Current Bangladesh administrative coverage: 8 divisions, 64 districts, and 500 upazilas (September 2026)
- Backend support for coordinate-based proximity search
- Direct donor calling
- Create and browse urgent blood requests
- Request owners can mark a request fulfilled
- Responsive Flutter UI for mobile and web
- Django admin for users, donors, and blood requests

## Project structure

```text
Accounts/          Django email user, role, and OTP models
Blood/             Django settings and root routes
Blood_app/         Website, donor/request models, REST API
flutter_app/       Flutter app (Android, iOS, web)
render.yaml        Render Blueprint
```

## Run the backend locally

Python 3.12 is recommended.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python manage.py migrate
python manage.py runserver
```

API health check: `http://127.0.0.1:8000/api/v1/health/`

API routes:

```text
POST   /api/v1/auth/register/          Request email OTP
POST   /api/v1/auth/register/verify/   Verify OTP and receive JWTs
POST   /api/v1/auth/register/resend/   Resend OTP
POST   /api/v1/auth/login/
POST   /api/v1/auth/refresh/
GET    /api/v1/profile/
PATCH  /api/v1/profile/
GET    /api/v1/donors/
GET    /api/v1/locations/
GET    /api/v1/requests/
POST   /api/v1/requests/
PATCH  /api/v1/requests/{id}/status/
PATCH  /api/v1/donors/{id}/availability/  Moderator/admin only
POST   /api/v1/moderation/donors/          Moderator/admin only
GET    /api/v1/admin/users/                Admin only
PATCH  /api/v1/admin/users/{id}/role/      Admin only
GET    /api/v1/admin/duplicates/           Admin only
POST   /api/v1/admin/duplicates/{id}/resolve/ Admin only
```

## Run Flutter

```bash
cd flutter_app
flutter pub get
flutter run
```

The app uses the deployed Render API by default. To develop against a local backend, override it with `--dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1/`. For an Android emulator, use `http://10.0.2.2:8000/api/v1/`.

## Deploy the API to Render with Neon

1. Create a Neon project and copy its pooled PostgreSQL connection string.
2. In Render, create a Blueprint from this repository using `render.yaml`.
3. Set the following Render environment variables:

```text
DATABASE_URL=<Neon pooled connection string ending in sslmode=require>
ALLOWED_HOSTS=<your-service>.onrender.com
CORS_ALLOWED_ORIGINS=https://<your-flutter-site>.vercel.app
CSRF_TRUSTED_ORIGINS=https://<your-service>.onrender.com,https://<your-flutter-site>.vercel.app
BREVO_API_KEY=<your Brevo API key>
BREVO_SENDER_EMAIL=<a sender verified by Brevo>
BREVO_SENDER_NAME=Rokto Dorkar
```

The Brevo sender email must be verified before production OTP delivery works. In local `DEBUG=True` development without a Brevo key, the OTP is printed in the Django terminal and returned as `debug_otp` for testing.

Create an admin after the first deployment from a Render shell:

```bash
python manage.py createsuperuser
```

Administrators can promote users to moderators from the Flutter Management area or Django admin. Moderators can add donors without accounts and manage donor availability. When that donor later registers with the same normalized phone number, the Flutter Management area alerts administrators, who can delete the manually created record or dismiss the match.

## Deploy Flutter web to Vercel

1. Import the repository in Vercel.
2. Set the Root Directory to `flutter_app`.
3. Add `API_BASE_URL=https://<your-service>.onrender.com/api/v1/`.
4. Deploy. `flutter_app/vercel.json` builds Flutter web and configures SPA routing.

## Build mobile releases

```bash
cd flutter_app
flutter build apk --release --dart-define=API_BASE_URL=https://<your-service>.onrender.com/api/v1/
flutter build appbundle --release --dart-define=API_BASE_URL=https://<your-service>.onrender.com/api/v1/
flutter build ipa --release --dart-define=API_BASE_URL=https://<your-service>.onrender.com/api/v1/
```

The iOS build requires Xcode signing. Play Store and App Store publishing credentials are not stored in this repository.

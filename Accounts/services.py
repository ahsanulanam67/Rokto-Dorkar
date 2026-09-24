import logging
import secrets
from datetime import timedelta

import requests
from django.conf import settings
from django.contrib.auth.hashers import check_password, make_password
from django.utils import timezone

from .models import EmailVerificationOTP


logger = logging.getLogger(__name__)


class OTPError(Exception):
    pass


class OTPCooldownError(OTPError):
    pass


class OTPDeliveryError(OTPError):
    pass


def issue_email_otp(user, enforce_cooldown=True):
    now = timezone.now()
    current = EmailVerificationOTP.objects.filter(user=user).first()
    if current and enforce_cooldown:
        available_at = current.last_sent_at + timedelta(seconds=settings.OTP_RESEND_SECONDS)
        if available_at > now:
            seconds = max(1, int((available_at - now).total_seconds()))
            raise OTPCooldownError(f"Please wait {seconds} seconds before requesting another code.")

    code = f"{secrets.randbelow(1_000_000):06d}"
    EmailVerificationOTP.objects.update_or_create(
        user=user,
        defaults={
            "code_hash": make_password(code),
            "expires_at": now + timedelta(minutes=settings.OTP_EXPIRY_MINUTES),
            "last_sent_at": now,
            "attempts": 0,
        },
    )
    _send_brevo_email(user.email, code)
    return code if settings.DEBUG and not settings.BREVO_API_KEY else None


def verify_email_otp(user, code):
    try:
        verification = user.verification_otp
    except EmailVerificationOTP.DoesNotExist as exc:
        raise OTPError("Request a new verification code.") from exc

    if verification.expires_at <= timezone.now():
        raise OTPError("This verification code has expired.")
    if verification.attempts >= settings.OTP_MAX_ATTEMPTS:
        raise OTPError("Too many attempts. Request a new verification code.")
    if not check_password(str(code).strip(), verification.code_hash):
        verification.attempts += 1
        verification.save(update_fields=("attempts",))
        raise OTPError("The verification code is incorrect.")

    user.email_verified = True
    user.is_active = True
    user.save(update_fields=("email_verified", "is_active"))
    verification.delete()
    return user


def _send_brevo_email(recipient, code):
    if not settings.BREVO_API_KEY:
        if settings.DEBUG:
            logger.warning("Development OTP for %s: %s", recipient, code)
            return
        raise OTPDeliveryError("Email service is not configured.")

    try:
        response = requests.post(
            "https://api.brevo.com/v3/smtp/email",
            headers={
                "accept": "application/json",
                "api-key": settings.BREVO_API_KEY,
                "content-type": "application/json",
            },
            json={
                "sender": {"name": settings.BREVO_SENDER_NAME, "email": settings.BREVO_SENDER_EMAIL},
                "to": [{"email": recipient}],
                "subject": "Your Rokto Dorkar verification code",
                "htmlContent": (
                    "<div style='font-family:Arial,sans-serif;max-width:520px;margin:auto'>"
                    "<h2 style='color:#b71c1c'>Rokto Dorkar</h2>"
                    "<p>Use this code to verify your email address:</p>"
                    f"<p style='font-size:32px;font-weight:bold;letter-spacing:8px'>{code}</p>"
                    f"<p>This code expires in {settings.OTP_EXPIRY_MINUTES} minutes.</p>"
                    "<p>If you did not request this code, you can ignore this email.</p></div>"
                ),
            },
            timeout=12,
        )
        response.raise_for_status()
    except requests.RequestException as exc:
        logger.exception("Brevo could not send an OTP")
        raise OTPDeliveryError("We could not send the verification email. Please try again.") from exc

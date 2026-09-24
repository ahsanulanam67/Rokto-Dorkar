import re


def normalize_phone(value):
    """Return Bangladesh mobile numbers in canonical 01XXXXXXXXX form."""
    digits = re.sub(r"\D", "", value or "")
    if digits.startswith("880"):
        digits = f"0{digits[3:]}"
    elif len(digits) == 10 and digits.startswith("1"):
        digits = f"0{digits}"
    return digits


def is_valid_bangladesh_phone(value):
    return bool(re.fullmatch(r"01[3-9]\d{8}", normalize_phone(value)))

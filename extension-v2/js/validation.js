// HomeScope – Validation Service
// Mirrors validation_service.dart exactly.

const POSTAL_PATTERNS = {
  PT: /^\d{4}-\d{3}$/,
  ES: /^\d{5}$/,
  GB: /^[A-Z]{1,2}[0-9][0-9A-Z]?\s[0-9][A-Z]{2}$/,
  FR: /^\d{5}$/,
  DE: /^\d{5}$/,
};

export function validateAddress(value) {
  if (!value || !value.trim()) return 'Address is required.';
  if (value.trim().length < 5) return 'Address must be at least 5 characters.';
  return null;
}

export function validatePostalCode(value, countryCode) {
  if (!value || !value.trim()) return null; // optional
  const pattern = POSTAL_PATTERNS[countryCode];
  if (!pattern) return null;
  if (!pattern.test(value.trim().toUpperCase())) {
    return `Invalid postal code for ${countryCode}.`;
  }
  return null;
}

export function validateRequired(value, field) {
  if (!value || !value.trim()) return `${field} is required.`;
  return null;
}

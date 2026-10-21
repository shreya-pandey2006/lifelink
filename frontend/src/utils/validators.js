/**
 * LifeLink frontend validation utilities.
 * Comprehensive client-side validators for user name, email, password, age, and weight.
 */

/**
 * Validates a user's full name.
 * @param {string} name
 * @returns {string|null} Error message or null if valid.
 */
export function validateName(name) {
  if (!name || !name.trim()) {
    return "Please enter your full name";
  }

  const trimmed = name.trim();

  if (trimmed.length < 2) {
    return "Name must be at least 2 characters";
  }

  if (trimmed.length > 60) {
    return "Name cannot exceed 60 characters";
  }

  // Must only contain letters, spaces, hyphens, periods, and apostrophes
  const allowedPattern = /^[a-zA-Z\u00C0-\u024F\u1E00-\u1EFF\s\-'.]+$/;
  if (!allowedPattern.test(trimmed)) {
    return "Name can only contain letters, spaces, hyphens and apostrophes";
  }

  // Must contain at least two alphabetic letters
  const letters = (trimmed.match(/[a-zA-Z\u00C0-\u024F\u1E00-\u1EFF]/g) || []).length;
  if (letters < 2) {
    return "Name must contain at least 2 letters";
  }

  // No consecutive punctuation
  if (/[\-'.]{2,}/.test(trimmed)) {
    return "Name cannot contain consecutive punctuation";
  }

  return null;
}

/**
 * Validates an email address.
 * @param {string} email
 * @returns {string|null} Error message or null if valid.
 */
export function validateEmail(email) {
  if (!email || !email.trim()) {
    return "Please enter your email address";
  }

  const trimmed = email.trim();

  if (trimmed.length > 100) {
    return "Email address cannot exceed 100 characters";
  }

  if (trimmed.includes(" ")) {
    return "Email address cannot contain spaces";
  }

  const emailRegex =
    /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$/;

  if (!emailRegex.test(trimmed) || trimmed.includes("..")) {
    return "Please enter a valid email address (e.g. name@example.com)";
  }

  const parts = trimmed.split("@");
  if (parts.length !== 2) {
    return "Please enter a valid email address";
  }

  const username = parts[0];
  const domain = parts[1].toLowerCase();

  if (username.length < 2) {
    return "Email username must be at least 2 characters";
  }

  // Reject pure consonant keyboard smashes with 3+ characters (e.g. "fhgj")
  if (username.length >= 3 && !/[aeiouy0-9]/i.test(username)) {
    return "Please enter a valid, realistic email address";
  }

  // Common domain typo detection
  const commonTypos = {
    "gail.com": "gmail.com",
    "gamil.com": "gmail.com",
    "gmial.com": "gmail.com",
    "gmai.com": "gmail.com",
    "gmal.com": "gmail.com",
    "gmaill.com": "gmail.com",
    "gmaik.com": "gmail.com",
    "gmaul.com": "gmail.com",
    "gmeil.com": "gmail.com",
    "yaho.com": "yahoo.com",
    "yahooo.com": "yahoo.com",
    "yhaoo.com": "yahoo.com",
    "hotmial.com": "hotmail.com",
    "hotmaill.com": "hotmail.com",
    "hotmil.com": "hotmail.com",
    "outlok.com": "outlook.com",
    "outloo.com": "outlook.com",
    "outlock.com": "outlook.com",
    "icoud.com": "icloud.com",
    "iclod.com": "icloud.com",
  };

  if (commonTypos[domain]) {
    return `Invalid email domain: Did you mean @${commonTypos[domain]}?`;
  }

  const disposableDomains = new Set([
    "tempmail.com",
    "10minutemail.com",
    "mailinator.com",
    "guerrillamail.com",
    "throwawaymail.com",
    "trashmail.com",
    "fakeinbox.com",
    "yopmail.com",
    "sharklasers.com",
    "getnada.com",
    "dispostable.com",
    "temp-mail.org",
  ]);

  if (disposableDomains.has(domain)) {
    return "Temporary or disposable email addresses are not allowed";
  }

  const domainParts = domain.split(".");
  if (domainParts.length < 2 || domainParts.some((p) => !p)) {
    return "Please enter a valid email domain (e.g. gmail.com)";
  }

  const tld = domainParts[domainParts.length - 1];
  if (tld.length < 2 || !/^[a-zA-Z]+$/.test(tld)) {
    return "Please enter a valid top-level domain (e.g. .com)";
  }

  if (domainParts[0].length < 2) {
    return "Email domain name must be at least 2 characters";
  }

  return null;
}

/**
 * Validates a password.
 * @param {string} password
 * @param {{ minLength?: number, requireMixed?: boolean }} options
 * @returns {string|null} Error message or null if valid.
 */
export function validatePassword(password, { minLength = 6, requireMixed = true } = {}) {
  if (!password) {
    return "Please enter your password";
  }

  if (password.length < minLength) {
    return `Password must be at least ${minLength} characters`;
  }

  if (password.length > 128) {
    return "Password cannot exceed 128 characters";
  }

  if (requireMixed) {
    const hasLetter = /[a-zA-Z]/.test(password);
    const hasDigit = /[0-9]/.test(password);

    if (!hasLetter && !hasDigit) {
      return "Password must contain at least one letter and one number";
    }
    if (!hasLetter) {
      return "Password must contain at least one letter";
    }
    if (!hasDigit) {
      return "Password must contain at least one number";
    }
  }

  return null;
}

/**
 * Validates password confirmation.
 * @param {string} confirmPassword
 * @param {string} originalPassword
 * @returns {string|null} Error message or null if valid.
 */
export function validateConfirmPassword(confirmPassword, originalPassword) {
  if (!confirmPassword) {
    return "Please confirm your password";
  }

  if (confirmPassword !== originalPassword) {
    return "Passwords do not match";
  }

  return null;
}

/**
 * Validates age as a positive whole integer.
 * @param {string|number} value
 * @param {{ min?: number, max?: number, fieldName?: string, isDonor?: boolean, required?: boolean }} options
 * @returns {string|null} Error message or null if valid.
 */
export function validateAge(value, { min = 18, max = 100, fieldName = "Age", isDonor = false, required = true } = {}) {
  const str = value !== undefined && value !== null ? String(value).trim() : "";

  if (!str) {
    if (!required) return null;
    return `Please enter ${fieldName}`;
  }

  if (str.includes(".") || str.includes(",")) {
    return `${fieldName} must be a whole number, not a decimal`;
  }

  const age = Number(str);
  if (!Number.isInteger(age) || isNaN(age)) {
    return `Please enter a valid age (whole number)`;
  }

  if (age < min) {
    if (isDonor && min === 18) {
      return "Donors must be at least 18 years old to donate blood";
    }
    return `${fieldName} must be at least ${min}`;
  }

  if (age > max) {
    return `${fieldName} cannot exceed ${max}`;
  }

  return null;
}

/**
 * Validates weight in kg (supports decimals).
 * @param {string|number} value
 * @param {{ min?: number, max?: number, fieldName?: string, isDonor?: boolean, required?: boolean }} options
 * @returns {string|null} Error message or null if valid.
 */
export function validateWeight(value, { min = 30, max = 300, fieldName = "Weight", isDonor = false, required = true } = {}) {
  const str = value !== undefined && value !== null ? String(value).trim().replace(",", ".") : "";

  if (!str) {
    if (!required) return null;
    return `Please enter ${fieldName}`;
  }

  const weight = Number(str);
  if (isNaN(weight)) {
    return `Please enter a valid weight in kg (e.g. 68.5)`;
  }

  if (weight <= 0) {
    return `${fieldName} must be a positive number`;
  }

  if (weight < min) {
    if (isDonor) {
      return `Donors must weigh at least ${min} kg (45+ kg recommended for donation)`;
    }
    return `${fieldName} must be at least ${min} kg`;
  }

  if (weight > max) {
    return `${fieldName} cannot exceed ${max} kg`;
  }

  return null;
}

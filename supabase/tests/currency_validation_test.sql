-- Property Tests: Currency Validation
-- Description: Test currency validation functions with property-based testing approach
-- Requirements: 14.1, 14.2, 14.3, 14.5

BEGIN;

-- Test setup
SELECT plan(6);

-- Property 45: Currency codes are validated
-- **Validates: Requirements 14.1, 14.2**
-- Test that valid currency codes return true
SELECT ok(
    validate_currency_code('USD') = TRUE AND
    validate_currency_code('EUR') = TRUE AND
    validate_currency_code('VND') = TRUE AND
    validate_currency_code('GBP') = TRUE AND
    validate_currency_code('JPY') = TRUE,
    'Property 45: Valid currency codes are accepted'
);

-- Test that invalid currency codes return false
SELECT ok(
    validate_currency_code('XXX') = FALSE AND
    validate_currency_code('INVALID') = FALSE AND
    validate_currency_code('US') = FALSE AND
    validate_currency_code('') = FALSE AND
    validate_currency_code(NULL) = FALSE,
    'Property 45: Invalid currency codes are rejected'
);

-- Test case insensitivity
SELECT ok(
    validate_currency_code('usd') = TRUE AND
    validate_currency_code('Eur') = TRUE AND
    validate_currency_code('vnd') = TRUE AND
    validate_currency_code('GbP') = TRUE,
    'Property 45: Currency validation is case insensitive'
);

-- Property 46: Numeric precision is preserved
-- **Validates: Requirements 14.2, 14.3, 14.5**
-- Test decimal places for different currency types
SELECT ok(
    get_currency_decimal_places('USD') = 2 AND
    get_currency_decimal_places('EUR') = 2 AND
    get_currency_decimal_places('GBP') = 2,
    'Property 46: Standard currencies have 2 decimal places'
);

-- Test zero decimal place currencies
SELECT ok(
    get_currency_decimal_places('JPY') = 0 AND
    get_currency_decimal_places('KRW') = 0 AND
    get_currency_decimal_places('VND') = 0,
    'Property 46: Zero decimal currencies have 0 decimal places'
);

-- Test currency amount formatting preserves precision
SELECT ok(
    format_currency_amount(123.456, 'USD') = 123.46 AND
    format_currency_amount(123.456, 'JPY') = 123 AND
    format_currency_amount(123.456, 'VND') = 123 AND
    format_currency_amount(123.456, 'BHD') = 123.456,
    'Property 46: Currency formatting preserves appropriate precision'
);

SELECT * FROM finish();

ROLLBACK;
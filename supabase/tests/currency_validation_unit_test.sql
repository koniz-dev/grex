-- Unit Tests: Currency Validation Functions
-- Description: Comprehensive unit tests for currency validation functionality
-- Requirements: 14.1, 14.2, 14.3, 14.5

BEGIN;

-- Test setup
SELECT plan(15);

-- Test 1: Valid currency codes
SELECT ok(validate_currency_code('USD'), 'USD is valid currency');
SELECT ok(validate_currency_code('EUR'), 'EUR is valid currency');
SELECT ok(validate_currency_code('GBP'), 'GBP is valid currency');
SELECT ok(validate_currency_code('VND'), 'VND is valid currency');
SELECT ok(validate_currency_code('JPY'), 'JPY is valid currency');

-- Test 2: Invalid currency codes
SELECT ok(NOT validate_currency_code('XXX'), 'XXX is invalid currency');
SELECT ok(NOT validate_currency_code('INVALID'), 'INVALID is invalid currency');
SELECT ok(NOT validate_currency_code('US'), 'US (too short) is invalid');
SELECT ok(NOT validate_currency_code(''), 'Empty string is invalid');
SELECT ok(NOT validate_currency_code(NULL), 'NULL is invalid');

-- Test 3: Case insensitivity
SELECT ok(validate_currency_code('usd'), 'Lowercase USD is valid');
SELECT ok(validate_currency_code('Eur'), 'Mixed case EUR is valid');

-- Test 4: Decimal places functionality
SELECT is(get_currency_decimal_places('USD'), 2, 'USD has 2 decimal places');
SELECT is(get_currency_decimal_places('JPY'), 0, 'JPY has 0 decimal places');
SELECT is(get_currency_decimal_places('BHD'), 3, 'BHD has 3 decimal places');

SELECT * FROM finish();

ROLLBACK;
-- Migration: Create Currency Validation Function
-- Description: Implement ISO 4217 currency code validation with support for common currencies
-- Requirements: 14.1, 14.2

-- Create function to validate ISO 4217 currency codes
CREATE OR REPLACE FUNCTION validate_currency_code(currency_code TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    -- Check if currency code is null or empty
    IF currency_code IS NULL OR LENGTH(TRIM(currency_code)) = 0 THEN
        RETURN FALSE;
    END IF;
    
    -- Check if currency code has correct length (3 characters)
    IF LENGTH(TRIM(currency_code)) != 3 THEN
        RETURN FALSE;
    END IF;
    
    -- Convert to uppercase for comparison
    currency_code := UPPER(TRIM(currency_code));
    
    -- Validate against supported ISO 4217 currency codes
    -- Including major world currencies and Vietnamese Dong
    RETURN currency_code IN (
        -- Major world currencies
        'USD', -- US Dollar
        'EUR', -- Euro
        'GBP', -- British Pound
        'JPY', -- Japanese Yen
        'CHF', -- Swiss Franc
        'CAD', -- Canadian Dollar
        'AUD', -- Australian Dollar
        'NZD', -- New Zealand Dollar
        'SEK', -- Swedish Krona
        'NOK', -- Norwegian Krone
        'DKK', -- Danish Krone
        'PLN', -- Polish Zloty
        'CZK', -- Czech Koruna
        'HUF', -- Hungarian Forint
        'RUB', -- Russian Ruble
        'CNY', -- Chinese Yuan
        'HKD', -- Hong Kong Dollar
        'SGD', -- Singapore Dollar
        'KRW', -- South Korean Won
        'THB', -- Thai Baht
        'MYR', -- Malaysian Ringgit
        'IDR', -- Indonesian Rupiah
        'PHP', -- Philippine Peso
        'VND', -- Vietnamese Dong
        'INR', -- Indian Rupee
        'PKR', -- Pakistani Rupee
        'BDT', -- Bangladeshi Taka
        'LKR', -- Sri Lankan Rupee
        'NPR', -- Nepalese Rupee
        'MMK', -- Myanmar Kyat
        'LAK', -- Lao Kip
        'KHR', -- Cambodian Riel
        'BND', -- Brunei Dollar
        'TWD', -- Taiwan Dollar
        'MOP', -- Macanese Pataca
        'BRL', -- Brazilian Real
        'ARS', -- Argentine Peso
        'CLP', -- Chilean Peso
        'COP', -- Colombian Peso
        'PEN', -- Peruvian Sol
        'MXN', -- Mexican Peso
        'ZAR', -- South African Rand
        'EGP', -- Egyptian Pound
        'MAD', -- Moroccan Dirham
        'TND', -- Tunisian Dinar
        'NGN', -- Nigerian Naira
        'KES', -- Kenyan Shilling
        'GHS', -- Ghanaian Cedi
        'XOF', -- West African CFA Franc
        'XAF', -- Central African CFA Franc
        'ETB', -- Ethiopian Birr
        'UGX', -- Ugandan Shilling
        'TZS', -- Tanzanian Shilling
        'RWF', -- Rwandan Franc
        'MWK', -- Malawian Kwacha
        'ZMW', -- Zambian Kwacha
        'BWP', -- Botswana Pula
        'SZL', -- Swazi Lilangeni
        'LSL', -- Lesotho Loti
        'NAD', -- Namibian Dollar
        'MZN', -- Mozambican Metical
        'AOA', -- Angolan Kwanza
        'BHD', -- Bahraini Dinar
        'IQD', -- Iraqi Dinar
        'JOD', -- Jordanian Dinar
        'KWD', -- Kuwaiti Dinar
        'LYD', -- Libyan Dinar
        'OMR', -- Omani Rial
        'XDR', -- Special Drawing Rights
        'XAU', -- Gold (troy ounce)
        'XAG', -- Silver (troy ounce)
        'XPT', -- Platinum (troy ounce)
        'XPD'  -- Palladium (troy ounce)
    );
END;
$$;

-- Create function to get currency decimal places for precision handling
CREATE OR REPLACE FUNCTION get_currency_decimal_places(currency_code TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    -- Validate currency code first
    IF NOT validate_currency_code(currency_code) THEN
        RETURN NULL;
    END IF;
    
    -- Convert to uppercase for comparison
    currency_code := UPPER(TRIM(currency_code));
    
    -- Return decimal places based on currency
    CASE currency_code
        -- Currencies with no decimal places
        WHEN 'JPY', 'KRW', 'VND', 'IDR', 'CLP', 'PYG', 'UGX', 'RWF', 'KMF', 'GNF', 'MGA', 'XOF', 'XAF' THEN
            RETURN 0;
        -- Currencies with 3 decimal places
        WHEN 'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND' THEN
            RETURN 3;
        -- Most currencies use 2 decimal places
        ELSE
            RETURN 2;
    END CASE;
END;
$$;

-- Create function to format amount according to currency precision
CREATE OR REPLACE FUNCTION format_currency_amount(amount DECIMAL, currency_code TEXT)
RETURNS DECIMAL
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    decimal_places INTEGER;
BEGIN
    -- Get decimal places for currency
    decimal_places := get_currency_decimal_places(currency_code);
    
    -- Return null if currency is invalid
    IF decimal_places IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Round to appropriate decimal places
    RETURN ROUND(amount, decimal_places);
END;
$$;

-- Add comments for documentation
COMMENT ON FUNCTION validate_currency_code(TEXT) IS 'Validates ISO 4217 currency codes against supported currencies';
COMMENT ON FUNCTION get_currency_decimal_places(TEXT) IS 'Returns the number of decimal places for a given currency code';
COMMENT ON FUNCTION format_currency_amount(DECIMAL, TEXT) IS 'Formats monetary amounts according to currency precision rules';
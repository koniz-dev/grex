# Apple OAuth Setup Guide for Grex

## Overview

This guide walks you through setting up Apple Sign In authentication for the Grex app using Supabase Auth.

## Prerequisites

- Supabase project created
- Apple Developer Account (paid membership required)
- Admin access to both platforms

## Step 1: Configure App ID in Apple Developer Portal

1. **Navigate to Apple Developer Portal**
   - Go to [Apple Developer Portal](https://developer.apple.com/account/)
   - Sign in with your Apple Developer account

2. **Create App ID**
   - Go to "Certificates, Identifiers & Profiles"
   - Click "Identifiers"
   - Click the "+" button to create new identifier
   - Select "App IDs" and click "Continue"

3. **Configure App ID**
   ```
   Description: Grex Expense Sharing App
   Bundle ID: io.grex.app (or your chosen bundle ID)
   ```

4. **Enable Sign In with Apple**
   - In the "Capabilities" section
   - Check "Sign In with Apple"
   - Click "Continue" then "Register"

## Step 2: Create Services ID

1. **Create Services ID**
   - In "Identifiers", click the "+" button
   - Select "Services IDs" and click "Continue"

2. **Configure Services ID**
   ```
   Description: Grex Web Service
   Identifier: io.grex.web (must be different from App ID)
   ```
   - Check "Sign In with Apple"
   - Click "Configure"

3. **Configure Sign In with Apple**
   - Primary App ID: Select the App ID created in Step 1
   - Web Domain: `supabase.co`
   - Return URLs: `https://[your-project-id].supabase.co/auth/v1/callback`
   - Replace `[your-project-id]` with your actual Supabase project ID
   - Click "Save" then "Continue" then "Register"

## Step 3: Create Private Key

1. **Navigate to Keys**
   - Go to "Certificates, Identifiers & Profiles" > "Keys"
   - Click the "+" button

2. **Create Key**
   ```
   Key Name: Grex Apple Sign In Key
   ```
   - Check "Sign In with Apple"
   - Click "Configure"
   - Select your Primary App ID
   - Click "Save"

3. **Register and Download**
   - Click "Continue" then "Register"
   - **IMPORTANT**: Download the .p8 file immediately
   - Note the Key ID (10-character string)
   - You cannot download this file again!

## Step 4: Get Team ID

1. **Find Team ID**
   - In Apple Developer Portal, go to "Membership"
   - Your Team ID is displayed (10-character string)
   - Copy this value

## Step 5: Configure Supabase

1. **Navigate to Supabase Dashboard**
   - Go to [Supabase Dashboard](https://supabase.com/dashboard)
   - Select your Grex project

2. **Enable Apple Provider**
   - Go to "Authentication" > "Providers"
   - Find "Apple" in the list
   - Toggle it to "Enabled"

3. **Add Apple Credentials**
   ```
   Services ID: io.grex.web (from Step 2)
   Team ID: [your-10-character-team-id] (from Step 4)
   Key ID: [your-10-character-key-id] (from Step 3)
   Private Key: [paste contents of .p8 file] (from Step 3)
   ```

4. **Configure Redirect URL**
   - The redirect URL should be automatically set to:
   - `https://[your-project-id].supabase.co/auth/v1/callback`
   - Verify this matches what you added in Apple Developer Portal

5. **Save Configuration**
   - Click "Save"

## Step 6: Configure iOS App (if applicable)

If you're building an iOS app, additional configuration is needed:

1. **Add Capability in Xcode**
   - Open your iOS project in Xcode
   - Select your target
   - Go to "Signing & Capabilities"
   - Click "+" and add "Sign In with Apple"

2. **Update Info.plist**
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLName</key>
       <string>io.supabase.grex</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>io.supabase.grex</string>
       </array>
     </dict>
   </array>
   ```

## Step 7: Test Configuration

1. **Test OAuth Flow**
   - Use Supabase Auth UI or your app to test
   - Click "Sign in with Apple"
   - Should redirect to Apple Sign In screen
   - After approval, should redirect back to your app

2. **Verify User Creation**
   - Check Supabase Dashboard > Authentication > Users
   - Should see new user created with Apple provider

## Environment Variables

Add these to your `.env` file for reference:

```env
# Apple OAuth (for reference - not needed in client)
APPLE_SERVICES_ID=io.grex.web
APPLE_TEAM_ID=your-team-id
APPLE_KEY_ID=your-key-id
# Private key is stored in Supabase dashboard only
```

## Troubleshooting

### Common Issues

1. **"invalid_client" Error**
   - Verify Services ID is correct
   - Check that Services ID has Sign In with Apple enabled
   - Ensure return URL matches exactly

2. **"invalid_grant" Error**
   - Check Team ID is correct
   - Verify Key ID matches the downloaded key
   - Ensure private key is pasted correctly (including headers)

3. **"redirect_uri_mismatch" Error**
   - Verify return URL in Apple Developer Portal matches Supabase
   - Check for typos in project ID
   - Ensure HTTPS is used

### Private Key Format

The private key should look like this:
```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
-----END PRIVATE KEY-----
```

### Development vs Production

**Development:**
- Can test with sandbox Apple IDs
- Use development certificates
- Test on simulator and device

**Production:**
- Use production certificates
- Submit app for App Store review
- Ensure privacy policy mentions Apple Sign In

## Security Considerations

1. **Private Key Protection**
   - Never expose private key in client-side code
   - Store securely in Supabase dashboard only
   - Rotate keys periodically

2. **Services ID Validation**
   - Use different Services ID for different environments
   - Validate return URLs match exactly

3. **User Privacy**
   - Respect user's choice to hide email
   - Handle anonymous relay emails properly
   - Implement proper data handling for privacy

## Apple Sign In Requirements

If your app uses Apple Sign In, Apple requires:

1. **Equivalent Sign In Options**
   - If you offer other social logins, Apple Sign In must be equally prominent
   - Apple Sign In button should appear first or at same level

2. **Privacy Compliance**
   - Respect user's privacy choices
   - Handle email hiding appropriately
   - Don't require additional personal information

3. **Button Guidelines**
   - Use official Apple Sign In button designs
   - Follow Apple's Human Interface Guidelines
   - Don't modify button appearance

## Next Steps

After completing this setup:

1. Test the OAuth flow thoroughly
2. Implement Apple Sign In button in your Flutter app
3. Test with multiple Apple IDs
4. Ensure compliance with Apple's guidelines
5. Test email hiding functionality
6. Prepare for App Store submission

## References

- [Apple Sign In Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Supabase Apple Auth Guide](https://supabase.com/docs/guides/auth/social-login/auth-apple)
- [Apple Developer Portal](https://developer.apple.com/account/)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple)
# Apple OAuth Setup Guide for Grex

## Overview

This guide walks you through setting up Apple Sign In authentication for the Grex app using Supabase Auth. Updated for 2025 with support for web, iOS, macOS, watchOS, and tvOS.

## Prerequisites

- Supabase project created
- Apple Developer Account (paid membership required - $99/year)
- Admin access to both platforms

## Important Notes

- Apple Sign In is required if you offer other social login options on iOS
- Users can choose to hide their email (relay email provided)
- Native implementation recommended for iOS/macOS apps
- Web implementation available for web-based apps
- Nonce usage recommended for enhanced security

## Step 1: Register Email Sources (Important)

1. **Navigate to Services Section**
   - Go to [Apple Developer Portal](https://developer.apple.com/account/)
   - Navigate to "Certificates, Identifiers & Profiles"
   - Go to "Services" section

2. **Register Email Sources**
   - Find "Sign in with Apple for Email Communication"
   - Register your email domain
   - This enables Apple to send relay emails when users hide their email
   - **Critical**: Without this, email relay won't work properly

## Step 2: Configure App ID

1. **Navigate to Identifiers**
   - Go to "Certificates, Identifiers & Profiles"
   - Click "Identifiers"
   - Click the "+" button to create new identifier
   - Select "App IDs" and click "Continue"

2. **Configure App ID**
   ```
   Description: Grex Expense Sharing App
   Bundle ID: io.grex.app (or your chosen bundle ID)
   Platform: iOS, macOS (select as needed)
   ```

3. **Enable Sign In with Apple**
   - In the "Capabilities" section
   - Check "Sign In with Apple"
   - Leave "Enable as a primary App ID" checked
   - **Note**: Server-to-Server notification endpoints not required for Supabase Auth
   - Click "Continue" then "Register"

## Step 3: Create Services ID (for Web/OAuth Flow)

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

3. **Configure Web Authentication**
   - **Primary App ID**: Select the App ID created in Step 2
   - **Web Domain**: 
     - For Supabase: `supabase.co`
     - For custom domain: `auth.grex.app` (if configured)
   - **Return URLs**: 
     - Production: `https://[your-project-id].supabase.co/auth/v1/callback`
     - Custom domain: `https://auth.grex.app/auth/v1/callback`
     - Local dev: `http://127.0.0.1:54321/auth/v1/callback`
   - Replace `[your-project-id]` with your actual Supabase project ID
   - Click "Save" then "Continue" then "Register"

**Important**: The Services ID is used as the Client ID in Supabase configuration.

## Step 4: Create Private Key

1. **Navigate to Keys**
   - Go to "Certificates, Identifiers & Profiles" > "Keys"
   - Click the "+" button

2. **Create Key**
   ```
   Key Name: Grex Apple Sign In Key
   ```
   - Check "Sign In with Apple"
   - Click "Configure"
   - Select your Primary App ID (from Step 2)
   - Click "Save"

3. **Register and Download**
   - Click "Continue" then "Register"
   - **CRITICAL**: Download the `.p8` file immediately
   - Note the Key ID (10-character alphanumeric string)
   - **You cannot download this file again!**
   - Store the file securely - treat it like a password

4. **Private Key Format**
   The downloaded file should look like:
   ```
   -----BEGIN PRIVATE KEY-----
   MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
   -----END PRIVATE KEY-----
   ```

## Step 5: Get Team ID

1. **Find Team ID**
   - In Apple Developer Portal, go to "Membership"
   - Your Team ID is displayed (10-character alphanumeric string)
   - Copy this value - you'll need it for Supabase configuration

## Step 6: Configure Supabase

1. **Navigate to Supabase Dashboard**
   - Go to [Supabase Dashboard](https://supabase.com/dashboard)
   - Select your Grex project

2. **Enable Apple Provider**
   - Go to "Authentication" > "Providers"
   - Find "Apple" in the list
   - Toggle it to "Enabled"

3. **Add Apple Credentials**
   ```
   Services ID (Client ID): io.grex.web (from Step 3)
   Team ID: [your-10-character-team-id] (from Step 5)
   Key ID: [your-10-character-key-id] (from Step 4)
   Private Key: [paste entire contents of .p8 file including headers] (from Step 4)
   ```

4. **Important Notes on Private Key**
   - Paste the entire content including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`
   - Ensure no extra spaces or line breaks
   - The key should be a single block of text

5. **Configure Redirect URL**
   - The redirect URL should be automatically set to:
   - `https://[your-project-id].supabase.co/auth/v1/callback`
   - Verify this matches what you added in Apple Developer Portal

6. **Optional: Add Additional Client IDs**
   - If using native iOS/macOS apps, add their bundle IDs here
   - Format: `io.grex.app,io.grex.app.ios`
   - This allows both web and native sign-in

7. **Save Configuration**
   - Click "Save"

## Step 7: Implementation in Flutter

### Web/OAuth Flow (Recommended for Flutter Web)

```dart
// Basic OAuth flow
await Supabase.instance.client.auth.signInWithOAuth(
  OAuthProvider.apple,
);

// With PKCE flow (more secure)
await Supabase.instance.client.auth.signInWithOAuth(
  OAuthProvider.apple,
  redirectTo: 'io.supabase.grex://login-callback',
);
```

### Native iOS/macOS Implementation

For native apps, use Apple's Authentication Services:

```dart
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

Future<void> signInWithAppleNative() async {
  try {
    // Request credential from Apple
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: generateNonce(), // Generate random nonce
    );

    // Sign in to Supabase with the credential
    final response = await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: credential.identityToken!,
      nonce: rawNonce, // Use the non-hashed nonce
    );

    // Handle user name (only provided on first sign-in)
    if (credential.givenName != null || credential.familyName != null) {
      final fullName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
      
      // Save to user metadata
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': fullName,
            'given_name': credential.givenName,
            'family_name': credential.familyName,
          },
        ),
      );
    }
  } catch (e) {
    print('Apple Sign In failed: $e');
  }
}

// Generate nonce for security
String generateNonce([int length = 32]) {
  const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
}
```

### Handling Email Relay

When users choose to hide their email, Apple provides a relay email:

```dart
// Check if email is a relay email
bool isAppleRelayEmail(String email) {
  return email.endsWith('@privaterelay.appleid.com');
}

// Handle relay email appropriately
if (isAppleRelayEmail(user.email)) {
  // User chose to hide their email
  // Use the relay email for communication
  // Apple will forward emails to the user's real email
}
```

## Step 8: iOS/macOS App Configuration (Native Apps)

If building native iOS/macOS apps:

1. **Add Capability in Xcode**
   - Open your iOS/macOS project in Xcode
   - Select your target
   - Go to "Signing & Capabilities"
   - Click "+" and add "Sign In with Apple"

2. **Update Info.plist for Deep Linking**
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

3. **Add Flutter Dependencies**
   ```yaml
   dependencies:
     sign_in_with_apple: ^5.0.0
     supabase_flutter: ^2.0.0
   ```

## Step 9: Test Configuration

1. **Test OAuth Flow (Web)**
   - Use your Flutter web app to test
   - Click "Sign in with Apple"
   - Should redirect to Apple consent screen
   - After approval, should redirect back to your app

2. **Test Native Flow (iOS/macOS)**
   - Run on physical device or simulator
   - Click "Sign in with Apple"
   - Should show native Apple Sign In sheet
   - Test with both real and sandbox Apple IDs

3. **Verify User Creation**
   - Check Supabase Dashboard > Authentication > Users
   - Should see new user created with Apple provider
   - Verify user metadata includes email (or relay email)

4. **Test Email Hiding**
   - Sign in and choose "Hide My Email"
   - Verify relay email is provided
   - Test sending email to relay address

5. **Test Name Handling**
   - Sign in for the first time
   - Verify name is captured and saved to metadata
   - Sign in again - name won't be provided second time
   - Verify app uses saved name from metadata

## Environment Variables

Add these to your `.env` file for reference:

```env
# Apple OAuth Configuration
APPLE_SERVICES_ID=io.grex.web
APPLE_TEAM_ID=your-team-id
APPLE_KEY_ID=your-key-id

# Note: Private key should ONLY be stored in Supabase dashboard
# Never commit the .p8 file or private key to version control
```

## Troubleshooting

### Common Issues

1. **"invalid_client" Error**
   - Verify Services ID is correct in Supabase
   - Check that Services ID has Sign In with Apple enabled
   - Ensure return URL matches exactly (including protocol)
   - Verify Web Domain is configured correctly

2. **"invalid_grant" Error**
   - Check Team ID is correct (10 characters)
   - Verify Key ID matches the downloaded key (10 characters)
   - Ensure private key is pasted correctly with headers
   - Verify no extra spaces or line breaks in private key
   - Check that the key hasn't been revoked

3. **"redirect_uri_mismatch" Error**
   - Verify return URL in Apple Developer Portal matches Supabase exactly
   - Check for typos in project ID
   - Ensure HTTPS is used (HTTP only for localhost)
   - Verify Web Domain is correct

4. **Email Not Provided**
   - User may have chosen "Hide My Email"
   - Check for relay email ending in @privaterelay.appleid.com
   - Ensure email sources are registered in Apple Developer Portal
   - Verify email scope is requested

5. **Name Not Provided on Subsequent Sign-Ins**
   - This is expected behavior - Apple only provides name on first sign-in
   - Save name to user metadata on first sign-in
   - Use saved metadata for subsequent sessions
   - Implement proper metadata handling in your app

6. **Native Sign In Not Working**
   - Verify "Sign In with Apple" capability is added in Xcode
   - Check bundle ID matches App ID in Apple Developer Portal
   - Ensure device/simulator is signed in to iCloud
   - Test on physical device (simulator may have limitations)

7. **Private Key Format Issues**
   - Ensure entire key is copied including headers
   - Format should be:
     ```
     -----BEGIN PRIVATE KEY-----
     [key content]
     -----END PRIVATE KEY-----
     ```
   - No extra spaces before or after
   - No line breaks within the key content

### Development vs Production

**Development:**
- Can test with sandbox Apple IDs
- Use development certificates
- Test on simulator and device
- Limited to registered test devices
- Faster iteration

**Production:**
- Use production certificates
- Submit app for App Store review
- Ensure privacy policy mentions Apple Sign In
- Remove development URLs
- Test with real Apple IDs

## Security Considerations

1. **Private Key Protection**
   - Never expose private key in client-side code
   - Store securely in Supabase dashboard only
   - Never commit .p8 file to version control
   - Rotate keys periodically (annually recommended)
   - Revoke compromised keys immediately

2. **Services ID Validation**
   - Use different Services IDs for different environments
   - Validate return URLs match exactly
   - Keep Services ID configuration up to date

3. **User Privacy**
   - Respect user's choice to hide email
   - Handle relay emails properly
   - Implement proper data handling for privacy
   - Don't require additional personal information
   - Follow Apple's privacy guidelines

4. **Nonce Usage**
   - Always use nonces for enhanced security
   - Generate cryptographically random nonces
   - Never reuse nonces
   - Validate nonces on the server side

5. **Token Storage**
   - Store tokens securely (encrypted storage, secure cookies)
   - Never expose tokens in URLs or logs
   - Implement proper token refresh logic
   - Clear tokens on logout

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
   - Don't hide or de-emphasize Apple Sign In option

2. **Privacy Compliance**
   - Respect user's privacy choices
   - Handle email hiding appropriately
   - Don't require additional personal information beyond what Apple provides
   - Implement proper data handling

3. **Button Guidelines**
   - Use official Apple Sign In button designs
   - Follow Apple's Human Interface Guidelines
   - Don't modify button appearance beyond allowed customizations
   - Use appropriate button text ("Sign in with Apple", "Sign up with Apple", "Continue with Apple")

4. **App Store Review**
   - Apple will verify proper implementation during review
   - Ensure Sign In with Apple works correctly
   - Test thoroughly before submission
   - Have privacy policy ready

## Using Management API (Alternative Configuration)

You can also configure Apple OAuth programmatically:

```bash
# Get your access token from https://supabase.com/dashboard/account/tokens
export SUPABASE_ACCESS_TOKEN="your-access-token"
export PROJECT_REF="your-project-ref"

# Configure Apple auth provider
curl -X PATCH "https://api.supabase.com/v1/projects/$PROJECT_REF/config/auth" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "external_apple_enabled": true,
    "external_apple_client_id": "io.grex.web",
    "external_apple_secret": "your-generated-secret-key"
  }'
```

## Next Steps

After completing this setup:

1. **Test thoroughly**
   - Test OAuth flow on web
   - Test native flow on iOS/macOS devices
   - Verify email relay works correctly
   - Test name handling on first and subsequent sign-ins
   - Test error scenarios

2. **Implement in Flutter app**
   - Add Apple Sign In button to your UI
   - Implement both web and native flows
   - Handle OAuth callbacks properly
   - Implement proper error handling
   - Save user name on first sign-in
   - Handle relay emails appropriately

3. **Prepare for production**
   - Remove development URLs
   - Test with real Apple IDs
   - Verify button placement and design
   - Update privacy policy
   - Prepare for App Store review

4. **Monitor and maintain**
   - Monitor authentication metrics
   - Set up error tracking
   - Keep credentials secure
   - Rotate keys annually
   - Stay updated with Apple's requirements

5. **Compliance**
   - Follow Apple's Human Interface Guidelines
   - Ensure equal prominence with other social logins
   - Respect user privacy choices
   - Handle email relay properly

## References

- [Supabase Apple Auth Documentation](https://supabase.com/docs/guides/auth/social-login/auth-apple)
- [Apple Sign In Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Apple Developer Portal](https://developer.apple.com/account/)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple)
- [Sign In with Apple JS](https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_js)
- [Apple Authentication Services](https://developer.apple.com/documentation/authenticationservices)
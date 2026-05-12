# Google OAuth Setup Guide for Grex

## Overview

This guide walks you through setting up Google OAuth authentication for the Grex app using Supabase Auth. Updated for 2025 with current best practices.

## Prerequisites

- Supabase project created
- Google Cloud Console account
- Admin access to both platforms

## Important Notes

- Google+ API is deprecated and no longer required
- Use Google Auth Platform console for configuration
- FedCM support required for Chrome's third-party cookie phase-out
- Nonce usage recommended for enhanced security

## Step 1: Create Google Cloud Project

1. **Navigate to Google Cloud Console**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Sign in with your Google account

2. **Create New Project**
   - Click "Select a project" dropdown
   - Click "New Project"
   - Enter project name: `grex-oauth`
   - Click "Create"

## Step 2: Configure OAuth Consent Screen

1. **Navigate to Google Auth Platform Console**
   - Go to [Google Auth Platform Console](https://console.cloud.google.com/apis/credentials/consent)
   - Select your project
   - Select "External" user type
   - Click "Create"

2. **Configure App Information**
   ```
   App name: Grex - Expense Sharing
   User support email: [your-email]
   Developer contact information: [your-email]
   ```

3. **Setup Required Scopes**
   - Click "Add or Remove Scopes"
   - Add these required scopes:
     - `openid` (add manually)
     - `.../auth/userinfo.email` (added by default)
     - `.../auth/userinfo.profile` (added by default)
   - Click "Update"
   - **Important**: Avoid adding sensitive or restricted scopes as they require verification

4. **Configure Branding (Optional but Recommended)**
   - Add app logo and name in the Branding section
   - This improves user trust and reduces phishing susceptibility
   - Brand verification may take a few business days

5. **Add Test Users** (for development)
   - Add your test email addresses
   - Click "Save and Continue"

## Step 3: Create OAuth Credentials

1. **Navigate to Credentials**
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth 2.0 Client IDs"

2. **Configure OAuth Client**
   ```
   Application type: Web application
   Name: Grex Supabase OAuth
   ```

3. **Add Authorized JavaScript Origins**
   - Click "Add URI" under "Authorized JavaScript origins"
   - For production: Add your app's URL (e.g., `https://grex.app`)
   - For development: Add `http://localhost:3000` (or your dev port)
   - **Important**: Remove localhost URLs before production deployment

4. **Add Authorized Redirect URIs**
   - Click "Add URI" under "Authorized redirect URIs"
   - Add: `https://[your-project-id].supabase.co/auth/v1/callback`
   - For local development: `http://127.0.0.1:54321/auth/v1/callback`
   - Replace `[your-project-id]` with your actual Supabase project ID
   - Click "Create"

5. **Save Credentials**
   - Copy the Client ID
   - Copy the Client Secret
   - Store these securely - you'll need them for Supabase

## Step 4: Configure Supabase

1. **Navigate to Supabase Dashboard**
   - Go to [Supabase Dashboard](https://supabase.com/dashboard)
   - Select your Grex project

2. **Enable Google Provider**
   - Go to "Authentication" > "Providers"
   - Find "Google" in the list
   - Toggle it to "Enabled"

3. **Add Google Credentials**
   ```
   Client ID: [paste from Google Cloud Console]
   Client Secret: [paste from Google Cloud Console]
   ```

4. **Configure Redirect URL**
   - The redirect URL should be automatically set to:
   - `https://[your-project-id].supabase.co/auth/v1/callback`
   - Verify this matches what you added in Google Cloud Console

5. **Optional: Configure Custom Domain**
   - For better user trust, set up a custom domain like `auth.grex.app`
   - This prevents users from seeing `<project-id>.supabase.co` in the consent screen
   - Configure in Supabase Dashboard > Settings > Custom Domains

6. **Save Configuration**
   - Click "Save"

## Step 5: Local Development Setup

For local development with Supabase CLI:

1. **Add Environment Variable**
   ```bash
   # In your .env file
   SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_SECRET="<client-secret>"
   ```

2. **Configure in supabase/config.toml**
   ```toml
   [auth.external.google]
   enabled = true
   client_id = "<client-id>"
   secret = "env(SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_SECRET)"
   skip_nonce_check = false
   ```

3. **Multiple Client IDs** (if needed for Web, iOS, Android)
   - Concatenate all client IDs with commas
   - Web client ID must be first in the list
   - Example: `"web-client-id,ios-client-id,android-client-id"`

## Step 6: Implementation in Flutter

### Basic OAuth Flow

```dart
// For implicit flow (simple web apps)
await Supabase.instance.client.auth.signInWithOAuth(
  OAuthProvider.google,
);

// For PKCE flow (recommended for better security)
await Supabase.instance.client.auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: 'io.supabase.grex://login-callback',
);
```

### Saving Google Tokens (Optional)

If you need to access Google services on behalf of the user:

```dart
final response = await Supabase.instance.client.auth.signInWithOAuth(
  OAuthProvider.google,
  queryParams: {
    'access_type': 'offline',
    'prompt': 'consent',
  },
);

// Extract tokens from the session
final session = response.session;
final providerToken = session?.providerToken; // Google access token
final providerRefreshToken = session?.providerRefreshToken; // Google refresh token
```

### Using Google One-Tap (Web Only)

For web applications, you can use Google's One-Tap UI:

```dart
// 1. Include Google's script in your HTML
// <script src="https://accounts.google.com/gsi/client" async></script>

// 2. Generate nonce for security
Future<List<String>> generateNonce() async {
  final nonce = base64Url.encode(List<int>.generate(32, (i) => Random.secure().nextInt(256)));
  final bytes = utf8.encode(nonce);
  final digest = sha256.convert(bytes);
  final hashedNonce = digest.toString();
  return [nonce, hashedNonce];
}

// 3. Handle the credential response
Future<void> handleGoogleSignIn(String credential, String nonce) async {
  final response = await Supabase.instance.client.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: credential,
    nonce: nonce,
  );
}
```

## Environment Variables

Add these to your `.env` file:

```env
# Google OAuth Configuration
SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID=your-google-client-id
SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_SECRET=your-google-client-secret

# Note: Client secret should only be used server-side
# Never expose it in client-side code
```

## Troubleshooting

### Common Issues

1. **"redirect_uri_mismatch" Error**
   - Verify redirect URI in Google Cloud Console matches Supabase exactly
   - Check for typos in project ID
   - Ensure HTTPS is used (HTTP only for localhost)
   - Verify both "Authorized JavaScript origins" and "Authorized redirect URIs" are configured

2. **"invalid_client" Error**
   - Verify Client ID and Secret are correct
   - Ensure OAuth consent screen is fully configured
   - Check that all required scopes are added

3. **"access_denied" Error**
   - Check OAuth consent screen configuration
   - Verify test users are added (for development)
   - Check app verification status
   - Ensure user has granted all required permissions

4. **Third-Party Cookie Issues (Chrome)**
   - Ensure `use_fedcm_for_prompt: true` is set in Google One-Tap configuration
   - Chrome is phasing out third-party cookies; FedCM is required
   - Test in Chrome's incognito mode to verify

5. **Nonce Validation Errors**
   - Ensure nonce is generated randomly for each request
   - Verify hashed nonce (SHA-256) is sent to Google
   - Verify plain nonce is sent to Supabase
   - Don't reuse nonces across requests

### Development vs Production

**Development:**
- Use "External" user type with test users
- App doesn't need to be verified
- Limited to 100 users
- Can use localhost URLs
- Faster iteration and testing

**Production:**
- Submit app for verification if using sensitive/restricted scopes
- Remove user limits after verification
- Update privacy policy and terms of service
- Remove all localhost URLs from authorized origins
- Consider custom domain for better branding
- Brand verification improves user trust

## Security Considerations

1. **Client Secret Protection**
   - Never expose client secret in client-side code
   - Store securely in environment variables or Supabase dashboard only
   - Use different secrets for development and production
   - Rotate secrets periodically

2. **Scope Minimization**
   - Only request necessary scopes (openid, email, profile)
   - Don't request additional permissions unnecessarily
   - Sensitive scopes require Google verification

3. **Redirect URI Validation**
   - Use HTTPS for all production redirect URIs
   - Validate redirect URIs match exactly
   - Remove development URLs before production deployment

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

## Using Management API (Alternative Configuration)

You can also configure Google OAuth programmatically:

```bash
# Get your access token from https://supabase.com/dashboard/account/tokens
export SUPABASE_ACCESS_TOKEN="your-access-token"
export PROJECT_REF="your-project-ref"

# Configure Google auth provider
curl -X PATCH "https://api.supabase.com/v1/projects/$PROJECT_REF/config/auth" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "external_google_enabled": true,
    "external_google_client_id": "your-client-id",
    "external_google_secret": "your-client-secret"
  }'
```

## Next Steps

After completing this setup:

1. **Test thoroughly**
   - Test OAuth flow on all target platforms
   - Verify token refresh works correctly
   - Test error scenarios (denied access, network issues)

2. **Configure Apple OAuth**
   - See `apple-oauth-setup.md` for Apple Sign In
   - Implement both providers for better user choice

3. **Implement in Flutter app**
   - Add Google Sign In button to your UI
   - Handle OAuth callbacks properly
   - Implement proper error handling
   - Test with multiple Google accounts

4. **Prepare for production**
   - Remove development URLs
   - Submit for verification if needed
   - Set up custom domain
   - Configure brand verification
   - Update privacy policy

5. **Monitor and maintain**
   - Monitor authentication metrics
   - Set up error tracking
   - Keep credentials secure
   - Rotate secrets periodically

## References

- [Supabase Google Auth Documentation](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Google Auth Platform Console](https://console.cloud.google.com/apis/credentials/consent)
- [Google Sign-In for Web](https://developers.google.com/identity/gsi/web)
- [Chrome FedCM Migration Guide](https://developers.google.com/identity/gsi/web/guides/fedcm-migration)
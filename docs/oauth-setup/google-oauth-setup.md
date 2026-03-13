# Google OAuth Setup Guide for Grex

## Overview

This guide walks you through setting up Google OAuth authentication for the Grex app using Supabase Auth.

## Prerequisites

- Supabase project created
- Google Cloud Console account
- Admin access to both platforms

## Step 1: Create Google Cloud Project

1. **Navigate to Google Cloud Console**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Sign in with your Google account

2. **Create New Project**
   - Click "Select a project" dropdown
   - Click "New Project"
   - Enter project name: `grex-oauth`
   - Click "Create"

## Step 2: Enable Google+ API

1. **Navigate to APIs & Services**
   - In the left sidebar, click "APIs & Services" > "Library"
   - Search for "Google+ API"
   - Click on "Google+ API"
   - Click "Enable"

## Step 3: Configure OAuth Consent Screen

1. **Navigate to OAuth Consent Screen**
   - Go to "APIs & Services" > "OAuth consent screen"
   - Select "External" user type
   - Click "Create"

2. **Fill App Information**
   ```
   App name: Grex - Expense Sharing
   User support email: [your-email]
   Developer contact information: [your-email]
   ```

3. **Add Scopes**
   - Click "Add or Remove Scopes"
   - Add these scopes:
     - `../auth/userinfo.email`
     - `../auth/userinfo.profile`
   - Click "Update"

4. **Add Test Users** (for development)
   - Add your test email addresses
   - Click "Save and Continue"

## Step 4: Create OAuth Credentials

1. **Navigate to Credentials**
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth 2.0 Client IDs"

2. **Configure OAuth Client**
   ```
   Application type: Web application
   Name: Grex Supabase OAuth
   ```

3. **Add Authorized Redirect URIs**
   - Click "Add URI"
   - Add: `https://[your-project-id].supabase.co/auth/v1/callback`
   - Replace `[your-project-id]` with your actual Supabase project ID
   - Click "Create"

4. **Save Credentials**
   - Copy the Client ID
   - Copy the Client Secret
   - Store these securely - you'll need them for Supabase

## Step 5: Configure Supabase

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

5. **Save Configuration**
   - Click "Save"

## Step 6: Test Configuration

1. **Test OAuth Flow**
   - Use Supabase Auth UI or your app to test
   - Click "Sign in with Google"
   - Should redirect to Google consent screen
   - After approval, should redirect back to your app

2. **Verify User Creation**
   - Check Supabase Dashboard > Authentication > Users
   - Should see new user created with Google provider

## Environment Variables

Add these to your `.env` file:

```env
# Google OAuth (for reference - not needed in client)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
```

## Troubleshooting

### Common Issues

1. **"redirect_uri_mismatch" Error**
   - Verify redirect URI in Google Cloud Console matches Supabase
   - Check for typos in project ID
   - Ensure HTTPS is used

2. **"invalid_client" Error**
   - Verify Client ID and Secret are correct
   - Check that Google+ API is enabled
   - Ensure OAuth consent screen is configured

3. **"access_denied" Error**
   - Check OAuth consent screen configuration
   - Verify test users are added (for development)
   - Check app verification status

### Development vs Production

**Development:**
- Use "External" user type with test users
- App doesn't need to be verified
- Limited to 100 users

**Production:**
- Submit app for verification
- Remove user limits
- Update privacy policy and terms of service

## Security Considerations

1. **Client Secret Protection**
   - Never expose client secret in client-side code
   - Store securely in Supabase dashboard only

2. **Scope Minimization**
   - Only request necessary scopes (email, profile)
   - Don't request additional permissions unnecessarily

3. **Redirect URI Validation**
   - Use HTTPS for all redirect URIs
   - Validate redirect URIs match exactly

## Next Steps

After completing this setup:

1. Test the OAuth flow thoroughly
2. Configure Apple OAuth (see apple-oauth-setup.md)
3. Implement social login in your Flutter app
4. Test with multiple Google accounts
5. Prepare for production verification if needed

## References

- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Google Cloud Console](https://console.cloud.google.com/)
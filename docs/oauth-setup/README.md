# OAuth Configuration for Grex Social Login

## Overview

This directory contains comprehensive guides for setting up OAuth providers (Google and Apple) for the Grex expense sharing app. These configurations enable users to sign in with their existing Google or Apple accounts instead of creating new passwords.

## Quick Start

1. **Google OAuth Setup**: Follow [google-oauth-setup.md](./google-oauth-setup.md)
2. **Apple OAuth Setup**: Follow [apple-oauth-setup.md](./apple-oauth-setup.md)
3. **Testing**: Use the procedures in [oauth-testing.md](./oauth-testing.md)

## Prerequisites

Before starting OAuth configuration, ensure you have:

- ✅ Supabase project created and accessible
- ✅ Google Cloud Console account (for Google OAuth)
- ✅ Apple Developer Account with paid membership (for Apple OAuth)
- ✅ Admin access to both platforms
- ✅ Flutter development environment set up

## Configuration Order

**Recommended setup order:**

1. **Google OAuth First** (easier setup, no paid account required)
   - Faster to test and validate
   - Good for initial development and testing
   - Works on all platforms (Android, iOS, Web)

2. **Apple OAuth Second** (requires paid Apple Developer account)
   - Required for iOS App Store submission if using social login
   - More complex setup process
   - iOS-specific requirements

## Required Credentials Summary

### Google OAuth Credentials
- **Client ID**: From Google Cloud Console
- **Client Secret**: From Google Cloud Console
- **Redirect URI**: `https://[project-id].supabase.co/auth/v1/callback`

### Apple OAuth Credentials
- **Services ID**: From Apple Developer Portal
- **Team ID**: From Apple Developer Portal (10 characters)
- **Key ID**: From Apple Developer Portal (10 characters)
- **Private Key**: Downloaded .p8 file content
- **Redirect URI**: `https://[project-id].supabase.co/auth/v1/callback`

## Environment Setup

### Development Environment Variables

Create or update your `.env` file:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# OAuth Provider References (for documentation)
GOOGLE_CLIENT_ID=your-google-client-id
APPLE_SERVICES_ID=io.grex.web
APPLE_TEAM_ID=your-team-id
APPLE_KEY_ID=your-key-id

# Note: OAuth secrets are stored in Supabase dashboard, not in .env
```

### Flutter Dependencies

Ensure these packages are in your `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^2.0.0
  app_links: ^3.4.0  # For deep link handling
  flutter_svg: ^2.0.0  # For provider icons

dev_dependencies:
  flutter_test:
    sdk: flutter
```

## Security Considerations

### Development vs Production

**Development:**
- Use test accounts and sandbox environments
- OAuth apps don't need verification
- Limited user access (100 users for Google)

**Production:**
- Submit apps for verification (Google)
- Follow App Store guidelines (Apple)
- Implement proper privacy policies
- Use production certificates and keys

### Credential Security

**✅ DO:**
- Store OAuth secrets only in Supabase dashboard
- Use environment variables for non-secret configuration
- Rotate keys periodically
- Use HTTPS for all redirect URIs

**❌ DON'T:**
- Expose client secrets in client-side code
- Commit OAuth credentials to version control
- Use HTTP for redirect URIs
- Share private keys via insecure channels

## Testing Strategy

### Manual Testing Checklist

After configuration, test these scenarios:

**Google OAuth:**
- [ ] Sign in with Google account
- [ ] User profile data retrieved correctly
- [ ] Session persists across app restarts
- [ ] Sign out works properly
- [ ] Error handling for cancelled sign-in

**Apple OAuth:**
- [ ] Sign in with Apple ID
- [ ] Handle email hiding option
- [ ] User profile data retrieved correctly
- [ ] Session persists across app restarts
- [ ] Sign out works properly

### Automated Testing

Run these tests after configuration:

```bash
# Test OAuth configuration
flutter test test/features/auth/oauth_test.dart

# Test social login integration
flutter test test/features/auth/social_login_test.dart

# Run all authentication tests
flutter test test/features/auth/
```

## Troubleshooting

### Common Issues

1. **Redirect URI Mismatch**
   - Verify URIs match exactly between provider and Supabase
   - Check for typos in project ID
   - Ensure HTTPS is used

2. **Invalid Client Errors**
   - Verify credentials are entered correctly
   - Check that APIs are enabled (Google+ API for Google)
   - Ensure OAuth consent screen is configured

3. **Permission Denied**
   - Check OAuth scopes are properly configured
   - Verify test users are added (development)
   - Ensure app verification status (production)

### Getting Help

If you encounter issues:

1. Check the troubleshooting sections in individual setup guides
2. Verify all prerequisites are met
3. Test with a fresh browser session
4. Check Supabase and provider dashboard logs
5. Consult the reference documentation links

## Development Workflow

### Local Development Focus

For active development:

1. **Use Supabase Cloud** (recommended)
   - Simpler setup than local Supabase
   - Matches production environment
   - OAuth providers work out of the box

2. **Test with Development Accounts**
   - Use test Google accounts
   - Use sandbox Apple IDs
   - Don't worry about app verification initially

3. **Iterate Quickly**
   - Test OAuth flows frequently
   - Use Flutter hot reload for UI changes
   - Mock OAuth responses for offline development

### Production Preparation

When ready for production:

1. **Submit for Verification**
   - Google: Submit OAuth app for verification
   - Apple: Ensure compliance with App Store guidelines

2. **Update Privacy Policies**
   - Document OAuth data usage
   - Explain user data handling
   - Provide opt-out mechanisms

3. **Security Review**
   - Audit OAuth configurations
   - Review credential storage
   - Test with production-like data

## File Structure

```
docs/oauth-setup/
├── README.md                 # This overview file
├── google-oauth-setup.md     # Google OAuth configuration guide
├── apple-oauth-setup.md      # Apple OAuth configuration guide
└── oauth-testing.md          # Testing procedures and checklists
```

## Next Steps

After completing OAuth configuration:

1. **Implement Social Login UI** - Create login buttons and flows
2. **Add Deep Link Handling** - Handle OAuth callbacks in your app
3. **Implement Profile Setup** - Handle new user onboarding
4. **Add Account Linking** - Connect social accounts to existing users
5. **Test Thoroughly** - Validate all OAuth flows work correctly

## References

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Apple Sign In Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Flutter Supabase Integration](https://supabase.com/docs/reference/dart/introduction)
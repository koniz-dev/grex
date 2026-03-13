# OAuth Provider Terms Compliance Documentation

## Overview

This document outlines the compliance measures implemented to ensure adherence to Google OAuth and Apple Sign In terms of service, developer policies, and platform requirements for the Grex social login system.

## Google OAuth Compliance

### Google Identity Platform Terms of Service

#### 1. Branding and User Experience Requirements
```dart
class GoogleBrandingCompliance {
  // Google Sign-In button implementation
  static Widget buildGoogleSignInButton(BuildContext context) {
    return SocialLoginButton(
      provider: SocialAuthProvider.google,
      // Follows Google branding guidelines
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,           // White background
        foregroundColor: Colors.black87,        // Dark text
        side: BorderSide(color: Colors.grey.shade300), // Light border
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
      ),
      // Uses official Google logo
      icon: SvgPicture.asset('assets/icons/google_logo.svg'),
      // Proper button text
      text: context.l10n.continueWithGoogle, // "Continue with Google"
    );
  }
}
```

**Compliance Requirements:**
- ✅ Uses official Google logo and branding
- ✅ Follows Google's button design guidelines
- ✅ Uses approved button text ("Continue with Google")
- ✅ Maintains proper logo proportions and spacing
- ✅ Implements consistent visual hierarchy

#### 2. Scope and Permission Requirements
```dart
class GoogleScopeCompliance {
  // Only request necessary scopes
  static const List<String> approvedScopes = [
    'email',    // User's email address
    'profile',  // Basic profile information
  ];
  
  // Prohibited scopes (not requested)
  static const List<String> prohibitedScopes = [
    'contacts',           // Contact list access
    'calendar',           // Calendar access
    'drive',              // Google Drive access
    'photos',             // Google Photos access
    'location',           // Location data
    'gmail',              // Gmail access
    'youtube',            // YouTube access
  ];
}
```

**Scope Compliance:**
- ✅ Requests only email and profile scopes
- ✅ No excessive permissions requested
- ✅ Clear justification for each scope
- ✅ User consent for data access
- ✅ Scope usage aligned with app functionality

#### 3. Data Usage and Privacy Requirements
```dart
class GoogleDataUsageCompliance {
  // Compliant data usage practices
  static const Map<String, String> dataUsage = {
    'email': 'User identification and account creation',
    'name': 'Personalization and user interface display',
    'picture': 'User avatar display (optional)',
    'id': 'Account linking and authentication',
  };
  
  // Data handling requirements
  static const DataHandlingPolicy policy = DataHandlingPolicy(
    minimumDataCollection: true,     // Collect only necessary data
    transparentUsage: true,          // Clear data usage disclosure
    userControl: true,               // User control over data
    secureStorage: true,             // Encrypted data storage
    limitedRetention: true,          // Data retention limits
    noDataSelling: true,             // No data selling to third parties
  );
}
```

**Data Usage Compliance:**
- ✅ Minimal data collection (email, name, profile picture)
- ✅ Transparent data usage disclosure
- ✅ User control over data sharing
- ✅ Secure data storage and transmission
- ✅ No data selling or unauthorized sharing
- ✅ Compliance with Google's User Data Policy

#### 4. Security Requirements
```dart
class GoogleSecurityCompliance {
  // OAuth 2.0 security implementation
  static Future<Either<AuthFailure, User>> signInWithGoogle() async {
    try {
      // Use Supabase OAuth with Google provider
      final response = await _supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.grex://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      
      // Implements PKCE (Proof Key for Code Exchange)
      // State parameter for CSRF protection
      // Secure redirect URI validation
      
      return _processOAuthResponse(response);
    } catch (e) {
      return Left(_mapAuthException(e));
    }
  }
}
```

**Security Compliance:**
- ✅ OAuth 2.0 with PKCE implementation
- ✅ CSRF protection via state parameter
- ✅ Secure redirect URI handling
- ✅ HTTPS-only communication
- ✅ Token secure storage
- ✅ Session management best practices

### Google Play Store Requirements

#### 1. App Store Listing Compliance
```yaml
# App metadata compliance
app_name: "Grex - Expense Sharing"
description: |
  Share expenses with friends and family. 
  Sign in with Google for quick and secure access.
  
privacy_policy_url: "https://grex.app/privacy"
terms_of_service_url: "https://grex.app/terms"

# Required disclosures
data_collection_disclosure: |
  This app collects email and profile information when you sign in with Google
  to provide authentication and personalization features.
```

#### 2. Permission Declarations
```xml
<!-- Android manifest permissions -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- No excessive permissions requested -->
<!-- Location, contacts, camera, etc. not requested -->
```

## Apple Sign In Compliance

### Apple Developer Program License Agreement

#### 1. Sign In with Apple Requirements
```dart
class AppleSignInCompliance {
  // Apple Sign In button implementation
  static Widget buildAppleSignInButton(BuildContext context) {
    return SocialLoginButton(
      provider: SocialAuthProvider.apple,
      // Follows Apple design guidelines
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.black,           // Black background
        foregroundColor: Colors.white,          // White text
        side: BorderSide(color: Colors.black),  // Black border
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
      ),
      // Uses official Apple logo
      icon: SvgPicture.asset('assets/icons/apple_logo.svg'),
      // Proper button text
      text: context.l10n.continueWithApple, // "Continue with Apple"
    );
  }
}
```

**Design Compliance:**
- ✅ Uses official Apple Sign In button styling
- ✅ Follows Apple Human Interface Guidelines
- ✅ Proper button text and iconography
- ✅ Consistent with iOS design patterns
- ✅ Appropriate button sizing and placement

#### 2. Privacy and Data Handling
```dart
class ApplePrivacyCompliance {
  // Apple's privacy-first approach
  static const PrivacyFeatures features = PrivacyFeatures(
    hideMyEmail: true,        // Support for Hide My Email
    minimalDataCollection: true, // Collect only necessary data
    userConsent: true,        // Explicit user consent
    dataTransparency: true,   // Clear data usage disclosure
    userControl: true,        // User control over data sharing
  );
  
  // Handle Apple's privacy features
  static Future<User> processAppleUser(AppleIdCredential credential) async {
    return User(
      id: credential.userIdentifier,
      // May be private relay email if user chose Hide My Email
      email: credential.email ?? '',
      // May be limited if user chose not to share
      displayName: credential.givenName != null && credential.familyName != null
          ? '${credential.givenName} ${credential.familyName}'
          : null,
      // Respect user's privacy choices
      emailConfirmed: credential.email != null,
    );
  }
}
```

**Privacy Compliance:**
- ✅ Supports Hide My Email feature
- ✅ Respects user privacy choices
- ✅ Minimal data collection
- ✅ Transparent data usage
- ✅ User control over shared information
- ✅ Compliance with App Store Review Guidelines

#### 3. App Store Review Guidelines
```dart
class AppStoreCompliance {
  // Guideline 4.8 - Sign In with Apple
  static const SignInRequirements requirements = SignInRequirements(
    // Required when other third-party sign-in options are available
    appleSignInRequired: true,
    
    // Must be equivalent option to other sign-in methods
    equivalentOption: true,
    
    // Must not require additional information beyond other methods
    noAdditionalInfo: true,
    
    // Must respect user's choice to use Apple Sign In
    respectUserChoice: true,
  );
}
```

**App Store Compliance:**
- ✅ Apple Sign In offered alongside Google Sign In
- ✅ Equivalent functionality to other sign-in methods
- ✅ No additional information required
- ✅ Respects user privacy preferences
- ✅ Follows App Store Review Guidelines 4.8

### iOS Platform Requirements

#### 1. iOS SDK Integration
```dart
class iOSIntegration {
  // Proper iOS integration
  static Future<void> configureAppleSignIn() async {
    // Configure iOS-specific settings
    if (Platform.isIOS) {
      // Set up proper URL scheme handling
      await _configureURLSchemes();
      
      // Configure keychain access
      await _configureKeychainAccess();
      
      // Set up proper app lifecycle handling
      await _configureAppLifecycle();
    }
  }
}
```

#### 2. Keychain and Security
```dart
class iOSSecurityCompliance {
  // iOS Keychain configuration
  static const IOSOptions keychainOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false, // Don't sync to iCloud for privacy
    accountName: 'grex_auth_tokens',
    groupId: null, // App-specific keychain access
  );
}
```

## Platform-Specific Implementation

### Android Implementation
```dart
class AndroidOAuthCompliance {
  // Android-specific OAuth configuration
  static Future<void> configureAndroidOAuth() async {
    // Configure deep link handling
    await _configureDeepLinks();
    
    // Set up secure storage
    await _configureSecureStorage();
    
    // Configure network security
    await _configureNetworkSecurity();
  }
  
  // Android manifest configuration
  static const AndroidManifestConfig manifestConfig = AndroidManifestConfig(
    deepLinkScheme: 'io.supabase.grex',
    deepLinkHost: 'login-callback',
    networkSecurityConfig: true,
    backupAllowBackup: false, // Prevent backup of sensitive data
  );
}
```

### iOS Implementation
```dart
class iOSOAuthCompliance {
  // iOS-specific OAuth configuration
  static Future<void> configureiOSOAuth() async {
    // Configure URL scheme handling
    await _configureURLSchemes();
    
    // Set up App Transport Security
    await _configureATS();
    
    // Configure background app refresh
    await _configureBackgroundRefresh();
  }
  
  // iOS Info.plist configuration
  static const iOSInfoPlistConfig plistConfig = iOSInfoPlistConfig(
    urlSchemes: ['io.supabase.grex'],
    atsSettings: ATSSettings(
      allowArbitraryLoads: false,
      requiresForwardSecrecy: true,
      minimumTLSVersion: '1.2',
    ),
  );
}
```

## Compliance Monitoring

### Automated Compliance Checks
```dart
class ComplianceMonitor {
  // Regular compliance validation
  static Future<ComplianceReport> validateCompliance() async {
    return ComplianceReport(
      googleCompliance: await _validateGoogleCompliance(),
      appleCompliance: await _validateAppleCompliance(),
      securityCompliance: await _validateSecurityCompliance(),
      privacyCompliance: await _validatePrivacyCompliance(),
      platformCompliance: await _validatePlatformCompliance(),
    );
  }
  
  static Future<GoogleComplianceStatus> _validateGoogleCompliance() async {
    return GoogleComplianceStatus(
      brandingCompliant: await _checkGoogleBranding(),
      scopeCompliant: await _checkGoogleScopes(),
      dataUsageCompliant: await _checkGoogleDataUsage(),
      securityCompliant: await _checkGoogleSecurity(),
    );
  }
}
```

### Manual Review Process
```dart
class ManualComplianceReview {
  // Quarterly compliance reviews
  static Future<void> conductQuarterlyReview() async {
    final checklist = ComplianceChecklist([
      // Google OAuth compliance
      'Google branding guidelines followed',
      'Google scope usage appropriate',
      'Google data usage policy compliant',
      'Google security requirements met',
      
      // Apple Sign In compliance
      'Apple design guidelines followed',
      'Apple privacy requirements met',
      'App Store guidelines compliant',
      'iOS platform requirements met',
      
      // General compliance
      'Privacy policy updated',
      'Terms of service current',
      'Data handling compliant',
      'Security measures adequate',
    ]);
    
    await _conductReview(checklist);
  }
}
```

## Documentation and Disclosure

### Privacy Policy Requirements
```markdown
# Privacy Policy - OAuth Provider Compliance

## Data Collection from OAuth Providers

### Google Sign-In
When you sign in with Google, we collect:
- Email address (for account identification)
- Display name (for personalization)
- Profile picture (optional, for avatar display)

### Apple Sign In
When you sign in with Apple, we collect:
- Email address (may be private relay email)
- Display name (if you choose to share)
- User identifier (for account linking)

## Data Usage
We use OAuth data solely for:
- User authentication and account management
- Personalizing your app experience
- Providing customer support

## Data Sharing
We do not sell or share your OAuth data with third parties except:
- With the OAuth provider for authentication purposes
- As required by law or legal process
- With your explicit consent

## Your Rights
You can:
- Access your data through your account settings
- Update your profile information
- Delete your account and associated data
- Withdraw consent for data processing
```

### Terms of Service Updates
```markdown
# Terms of Service - OAuth Integration

## Third-Party Authentication
Our app integrates with Google and Apple authentication services.
By using these services, you agree to their respective terms:
- Google Terms of Service: https://policies.google.com/terms
- Apple Terms of Service: https://www.apple.com/legal/internet-services/terms/

## Data Processing
We process OAuth data in accordance with:
- Our Privacy Policy
- Google's User Data Policy
- Apple's App Store Review Guidelines
- Applicable privacy laws (GDPR, CCPA)
```

## Compliance Training

### Developer Training Program
```dart
class ComplianceTraining {
  static const List<TrainingModule> modules = [
    TrainingModule(
      title: 'Google OAuth Compliance',
      topics: [
        'Google Identity Platform policies',
        'Branding and UX requirements',
        'Data usage policies',
        'Security requirements',
      ],
    ),
    TrainingModule(
      title: 'Apple Sign In Compliance',
      topics: [
        'Apple Developer Program requirements',
        'App Store Review Guidelines',
        'Privacy and data handling',
        'iOS platform integration',
      ],
    ),
    TrainingModule(
      title: 'Privacy Law Compliance',
      topics: [
        'GDPR requirements',
        'CCPA compliance',
        'Data minimization',
        'User rights implementation',
      ],
    ),
  ];
}
```

## Incident Response

### Compliance Violation Response
```dart
class ComplianceIncidentResponse {
  static Future<void> handleComplianceViolation(
    ComplianceViolation violation,
  ) async {
    // 1. Immediate assessment
    final severity = await _assessViolationSeverity(violation);
    
    // 2. Immediate remediation
    if (severity == ViolationSeverity.critical) {
      await _implementImmediateRemediation(violation);
    }
    
    // 3. Provider notification (if required)
    if (violation.requiresProviderNotification) {
      await _notifyOAuthProvider(violation);
    }
    
    // 4. App store notification (if required)
    if (violation.requiresAppStoreNotification) {
      await _notifyAppStore(violation);
    }
    
    // 5. User notification (if required)
    if (violation.requiresUserNotification) {
      await _notifyUsers(violation);
    }
    
    // 6. Documentation and reporting
    await _documentViolation(violation);
  }
}
```

## Regular Updates and Maintenance

### Policy Update Monitoring
```dart
class PolicyUpdateMonitor {
  // Monitor OAuth provider policy changes
  static Future<void> checkForPolicyUpdates() async {
    final updates = await Future.wait([
      _checkGooglePolicyUpdates(),
      _checkApplePolicyUpdates(),
      _checkPlatformUpdates(),
    ]);
    
    for (final update in updates.where((u) => u.hasUpdates)) {
      await _processPolicyUpdate(update);
    }
  }
}
```

### Compliance Maintenance Schedule
- **Weekly**: Automated compliance checks
- **Monthly**: Manual compliance review
- **Quarterly**: Comprehensive compliance audit
- **Annually**: External compliance assessment
- **Ad-hoc**: Policy change response

---

**Document Version**: 1.0  
**Last Updated**: December 2024  
**Next Review**: March 2025  
**Owner**: Compliance Team
# Grex Authentication Flow Design

## Overview

This directory contains the complete UI/UX design for the Grex authentication flow, created as a `.pen` file for the Pencil design tool.

## Design File

**File**: `authentication-flow.pen` (currently open in Pencil editor as `pencil-new.pen`)

**To save**: Use the Pencil editor's "Save As" function to save the current document to `designs/authentication-flow.pen`

## Authentication Screens Included

### 1. Login Screen
- **Location**: (0, 0)
- **Features**:
  - App logo and branding
  - Email input field
  - Password input field
  - "Forgot password?" link
  - Social login options (Google, Apple)
  - "or" divider
  - Primary "Sign In" button
  - "Don't have an account? Register" link

### 2. Register Screen
- **Location**: (450, 0)
- **Features**:
  - Display name input
  - Email input
  - Password input with strength requirements hint
  - Preferred currency selector (dropdown)
  - Social login options (Google, Apple)
  - "or" divider
  - Primary "Create Account" button
  - "Already have an account? Sign In" link

### 3. Forgot Password Screen
- **Location**: (900, 0)
- **Features**:
  - Back button
  - Email input field
  - "Send Reset Link" button
  - "Remember your password? Sign In" link

### 4. Reset Password Screen
- **Location**: (1350, 0)
- **Features**:
  - New password input
  - Confirm password input
  - Password strength requirements hint
  - "Reset Password" button

### 5. Email Verification Screen
- **Location**: (1800, 0)
- **Features**:
  - Mail icon in circular background
  - Verification instructions
  - User's email address display
  - "Resend Verification Email" button
  - Help text for spam folder
  - "Wrong email? Go back" link

### 6. Profile Setup Screen
- **Location**: (2250, 0)
- **Features**:
  - Progress indicator bar
  - Avatar upload section with placeholder
  - Display name input
  - Preferred currency selector
  - Language selector
  - "Continue" button
  - "Skip for now" option

### 7. Login - Loading State
- **Location**: (0, 950)
- **Features**:
  - Same as login screen
  - Disabled button with loading spinner
  - "Signing in..." text
  - Grayed out button to indicate processing

### 8. Login - Error State
- **Location**: (450, 950)
- **Features**:
  - Error banner with alert icon
  - Error message: "Invalid email or password. Please try again."
  - Red borders on input fields
  - All other login elements present

### 9. Success State
- **Location**: (900, 950)
- **Features**:
  - Large checkmark icon in black circle
  - "Welcome Back!" title
  - Success message
  - "Redirecting you to your dashboard..." text

## Design System

### Typography
- **Display Font**: Outfit (800 weight for titles, 600 for buttons)
- **Body Font**: Inter (400-600 weights)
- **Sizes**: 40px (titles), 32px (app name), 16px (buttons), 14px (body), 13px (labels), 12px (hints)

### Colors
- **Primary**: #000000 (Black) - buttons, active states
- **Background**: #FFFFFF (White)
- **Surface**: #F4F4F5 (Light gray) - input fields
- **Text Primary**: #000000 (Black)
- **Text Secondary**: #71717A (Gray)
- **Text Tertiary**: #A1A1AA (Light gray)
- **Error**: #DC2626 (Red)
- **Error Background**: #FEF0E8 (Light peach)

### Spacing
- **Screen padding**: 24px horizontal, 24px bottom
- **Section gap**: 32px vertical
- **Form field gap**: 16px
- **Label to input**: 6px
- **Input height**: 48px
- **Button height**: 56px

### Border Radius
- **Buttons**: 16px
- **Input fields**: 16px
- **Cards/Banners**: 12px
- **Avatar circles**: 40px (80px diameter)
- **Icons**: 12px

### Icons
- **Icon Set**: Lucide
- **Sizes**: 48px (logo), 40px (large icons), 20px (small icons)

## User Flow

```
Login Screen
├─→ Register Screen → Email Verification → Profile Setup → Success
├─→ Forgot Password → Reset Password → Login
└─→ Success State (after successful login)

States:
- Default (empty fields)
- Loading (during authentication)
- Error (validation/auth failures)
- Success (authentication complete)
```

## Authentication Features Supported

Based on the Grex project requirements:

1. **User Registration** (Requirement 1)
   - Email and password validation
   - Display name collection
   - Currency preference selection
   - Email verification flow

2. **User Login** (Requirement 2)
   - Email/password authentication
   - Session establishment
   - Error handling for invalid credentials

3. **Profile Management** (Requirement 3)
   - Display name editing
   - Currency preference
   - Language selection
   - Avatar upload

4. **Password Reset** (Requirement 4)
   - Email-based reset link
   - New password entry with validation
   - Confirmation field

5. **Session Management** (Requirement 5, 6)
   - Sign out capability
   - Session persistence (handled by backend)

6. **Email Verification** (Requirement 7)
   - Verification email sending
   - Resend capability
   - Status display

## Implementation Notes

### Supabase Integration
- All screens designed to work with Supabase Auth
- Email verification uses Supabase's built-in email service
- Password reset leverages Supabase's reset flow
- User profile data stored in `users` table

### Flutter Implementation
- Use `flutter_bloc` for state management
- Implement `AuthBloc` for authentication flows
- Implement `ProfileBloc` for profile management
- Use `supabase_flutter` package for backend integration

### Validation Rules
- **Email**: RFC 5322 compliant format
- **Password**: Minimum 8 characters, mixed case, numbers
- **Display Name**: 1-100 characters, non-empty
- **Currency**: ISO 4217 3-letter codes (VND, USD, etc.)
- **Language**: ISO 639-1 2-letter codes (en, vi, es, ar)

### Accessibility
- All text has sufficient contrast ratios
- Touch targets are minimum 48px
- Clear visual feedback for all states
- Error messages are descriptive and actionable

### Responsive Design
- Designed for mobile (402px width)
- Vertical scrolling for longer forms
- Flexible spacing using fill_container
- Adapts to different screen heights

## Next Steps

1. **Save the design file** from Pencil editor to `designs/authentication-flow.pen`
2. **Review with stakeholders** for approval
3. **Begin Flutter implementation** following the design specs
4. **Implement BLoC state management** for authentication flows
5. **Integrate with Supabase** backend
6. **Add localization** for all user-facing strings
7. **Test on multiple devices** and screen sizes
8. **Implement property-based tests** as defined in requirements

## Design Principles Applied

- **Clean & Minimal**: Monochrome design with clear hierarchy
- **Modern**: Bold typography with Outfit font family
- **Approachable**: Soft corners and friendly messaging
- **Professional**: Consistent spacing and alignment
- **Mobile-First**: Optimized for mobile experience
- **Accessible**: High contrast and clear visual feedback

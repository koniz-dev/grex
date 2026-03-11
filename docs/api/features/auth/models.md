# Auth Models

Data models for authentication.

## Overview

Models represent data structures used in the authentication flow, including user data and authentication responses.

---

## User Entity

Domain entity representing a user.

**Location:** `lib/features/auth/domain/entities/user.dart`

### Properties

```dart
/// Unique user identifier
final String id;

/// User's email address
final String email;

/// User's display name
final String? name;

/// URL to user's avatar image
final String? avatarUrl;
```

### Constructor

```dart
/// Creates a [User] with the given [id], [email], optional [name], and
/// optional [avatarUrl]
const User({
  required this.id,
  required this.email,
  this.name,
  this.avatarUrl,
});
```

### Usage

```dart
const user = User(
  id: '123',
  email: 'user@example.com',
  name: 'John Doe',
  avatarUrl: 'https://example.com/avatar.jpg',
);
```

---

## UserModel

Data model for user, extends User entity.

**Location:** `lib/features/auth/data/models/user_model.dart`

### Methods

```dart
/// Create UserModel from JSON
factory UserModel.fromJson(Map<String, dynamic> json);

/// Convert UserModel to JSON
Map<String, dynamic> toJson();

/// Convert UserModel to User entity
User toEntity();
```

### Usage

```dart
// From JSON
final json = {'id': '123', 'email': 'user@example.com', 'name': 'John'};
final userModel = UserModel.fromJson(json);

// To JSON
final json = userModel.toJson();

// To entity
final user = userModel.toEntity();
```

---

## User and session

Auth uses the Supabase Auth SDK; the domain [User](lib/features/auth/domain/entities/user.dart) entity is mapped from `supabase.User`. Session data (tokens, user, profile) is stored by [SecureSessionService](lib/features/auth/data/services/secure_session_service.dart) and synced to [AppConstants.tokenKey](lib/core/constants/app_constants.dart) for [AuthInterceptor](lib/core/network/interceptors/auth_interceptor.dart). User profile is in [UserProfile](lib/features/auth/domain/entities/user_profile.dart) and [UserModel](lib/features/auth/data/models/user_model.dart) for JSON.

---

## Related APIs

- [Repositories](repositories.md) - Uses these models
- [Use Cases](usecases.md) - Returns User entities
- [Providers](providers.md) - Provides data sources that use models


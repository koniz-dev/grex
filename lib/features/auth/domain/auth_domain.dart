// Entities
export 'entities/failures.dart';
export 'entities/user.dart';
export 'entities/user_profile.dart';

// Failures (user_failure adds extra types; UserFailure etc. from entities/failures)
export 'failures/user_failure.dart' hide InvalidUserDataFailure, UserFailure, UserNotFoundFailure;

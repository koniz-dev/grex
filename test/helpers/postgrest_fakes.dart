import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A Postgrest builder that resolves to a fixed value.
///
/// Supabase's builders are awaited directly rather than returning a plain
/// `Future`, so a terminal call like `.maybeSingle()` has to satisfy both
/// `PostgrestTransformBuilder<T>` and `Future<T>`. A mock cannot express that,
/// which is why this is a hand-written fake.
///
/// ```dart
/// when(() => filterBuilder.maybeSingle()).thenAnswer(
///   (_) => FakePostgrestTransformBuilder<PostgrestMap?>(
///     {'currency': 'USD'},
///   ),
/// );
/// ```
class FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T>, Future<T> {
  /// Creates a builder that resolves to [_value].
  FakePostgrestTransformBuilder(this._value);

  final T _value;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) async {
    return onValue(_value);
  }

  @override
  Future<T> catchError(
    Function onError, {
    bool Function(Object)? test,
  }) {
    return Future<T>.value(_value);
  }

  @override
  Stream<T> asStream() => Stream<T>.value(_value);

  @override
  Future<T> timeout(
    Duration timeLimit, {
    FutureOr<T> Function()? onTimeout,
  }) {
    return Future<T>.value(_value);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return Future<T>.value(_value);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/l10n/app_localizations.dart';

/// Unit tests for social login localization
///
/// Tests that all social login strings exist in all supported languages
/// and that placeholder replacement works correctly.
void main() {
  group('Social Login Localization', () {
    late AppLocalizations englishL10n;
    late AppLocalizations vietnameseL10n;
    late AppLocalizations spanishL10n;
    late AppLocalizations arabicL10n;

    setUpAll(() async {
      englishL10n = await AppLocalizations.delegate.load(const Locale('en'));
      vietnameseL10n = await AppLocalizations.delegate.load(const Locale('vi'));
      spanishL10n = await AppLocalizations.delegate.load(const Locale('es'));
      arabicL10n = await AppLocalizations.delegate.load(const Locale('ar'));
    });

    group('English Localization', () {
      test('should have all social login strings', () {
        expect(englishL10n.continueWithGoogle, equals('Continue with Google'));
        expect(englishL10n.continueWithApple, equals('Continue with Apple'));
        expect(englishL10n.or, equals('or'));
        expect(
          englishL10n.completeYourProfile,
          equals('Complete Your Profile'),
        );
        expect(
          englishL10n.profileSetupDescription,
          equals('Please complete your profile to get started with Grex'),
        );
        expect(englishL10n.linkYourAccount, equals('Link Your Account'));
        expect(englishL10n.linkAccounts, equals('Link Accounts'));
        expect(englishL10n.createNewAccount, equals('Create New Account'));
        expect(
          englishL10n.socialAuthFailed,
          equals('Authentication failed. Please try again.'),
        );
        expect(
          englishL10n.socialAuthNetworkError,
          equals(
            'Network connection failed. Please check your internet '
            'connection and try again.',
          ),
        );
        expect(
          englishL10n.socialAuthTimeout,
          equals('Authentication timed out. Please try again.'),
        );
        expect(
          englishL10n.accountLinkingError,
          equals(
            'Failed to link your account. Please try again or contact support.',
          ),
        );
        expect(englishL10n.cancelProfileSetup, equals('Cancel Setup'));
        expect(
          englishL10n.cancelProfileSetupMessage,
          equals(
            'Are you sure you want to cancel? You will be signed out and '
            'need to sign in again.',
          ),
        );
        expect(englishL10n.continueSetup, equals('Continue Setup'));
        expect(englishL10n.signInWithEmail, equals('Sign in with email'));
        expect(
          englishL10n.linkAccountBenefit,
          equals('This will allow you to sign in with either method.'),
        );
      });

      test('should handle parameterized strings', () {
        expect(
          englishL10n.accountExistsMessage('test@example.com'),
          equals('An account with email test@example.com already exists.'),
        );
        expect(
          englishL10n.linkAccountQuestion('Google'),
          equals(
            'Would you like to link your Google account to your existing '
            'account?',
          ),
        );
        expect(
          englishL10n.linkAccountQuestion('Apple'),
          equals(
            'Would you like to link your Apple account to your existing '
            'account?',
          ),
        );
      });
    });

    group('Vietnamese Localization', () {
      test('should have all social login strings', () {
        expect(
          vietnameseL10n.continueWithGoogle,
          equals('Tiếp tục với Google'),
        );
        expect(vietnameseL10n.continueWithApple, equals('Tiếp tục với Apple'));
        expect(vietnameseL10n.or, equals('hoặc'));
        expect(
          vietnameseL10n.completeYourProfile,
          equals('Hoàn thiện hồ sơ của bạn'),
        );
        expect(
          vietnameseL10n.profileSetupDescription,
          equals('Vui lòng hoàn thiện hồ sơ để bắt đầu sử dụng Grex'),
        );
        expect(
          vietnameseL10n.linkYourAccount,
          equals('Liên kết tài khoản của bạn'),
        );
        expect(vietnameseL10n.linkAccounts, equals('Liên kết tài khoản'));
        expect(vietnameseL10n.createNewAccount, equals('Tạo tài khoản mới'));
        expect(
          vietnameseL10n.socialAuthFailed,
          equals('Xác thực thất bại. Vui lòng thử lại.'),
        );
        expect(
          vietnameseL10n.socialAuthNetworkError,
          equals(
            'Kết nối mạng thất bại. Vui lòng kiểm tra kết nối internet và '
            'thử lại.',
          ),
        );
        expect(
          vietnameseL10n.socialAuthTimeout,
          equals('Xác thực hết thời gian chờ. Vui lòng thử lại.'),
        );
        expect(
          vietnameseL10n.accountLinkingError,
          equals(
            'Không thể liên kết tài khoản của bạn. Vui lòng thử lại hoặc '
            'liên hệ hỗ trợ.',
          ),
        );
        expect(vietnameseL10n.cancelProfileSetup, equals('Hủy thiết lập'));
        expect(
          vietnameseL10n.cancelProfileSetupMessage,
          equals(
            'Bạn có chắc chắn muốn hủy không? Bạn sẽ được đăng xuất và cần '
            'đăng nhập lại.',
          ),
        );
        expect(vietnameseL10n.continueSetup, equals('Tiếp tục thiết lập'));
        expect(vietnameseL10n.signInWithEmail, equals('Đăng nhập bằng email'));
        expect(
          vietnameseL10n.linkAccountBenefit,
          equals('Điều này sẽ cho phép bạn đăng nhập bằng cả hai phương thức.'),
        );
      });

      test('should handle parameterized strings', () {
        expect(
          vietnameseL10n.accountExistsMessage('test@example.com'),
          equals('Một tài khoản với email test@example.com đã tồn tại.'),
        );
        expect(
          vietnameseL10n.linkAccountQuestion('Google'),
          equals(
            'Bạn có muốn liên kết tài khoản Google của mình với tài khoản '
            'hiện có không?',
          ),
        );
        expect(
          vietnameseL10n.linkAccountQuestion('Apple'),
          equals(
            'Bạn có muốn liên kết tài khoản Apple của mình với tài khoản '
            'hiện có không?',
          ),
        );
      });
    });

    group('Spanish Localization', () {
      test('should have all social login strings', () {
        expect(spanishL10n.continueWithGoogle, equals('Continuar con Google'));
        expect(spanishL10n.continueWithApple, equals('Continuar con Apple'));
        expect(spanishL10n.or, equals('o'));
        expect(spanishL10n.completeYourProfile, equals('Completa tu perfil'));
        expect(
          spanishL10n.profileSetupDescription,
          equals('Por favor completa tu perfil para comenzar a usar Grex'),
        );
        expect(spanishL10n.linkYourAccount, equals('Vincular tu cuenta'));
        expect(spanishL10n.linkAccounts, equals('Vincular cuentas'));
        expect(spanishL10n.createNewAccount, equals('Crear nueva cuenta'));
        expect(
          spanishL10n.socialAuthFailed,
          equals('La autenticación falló. Por favor intenta de nuevo.'),
        );
        expect(
          spanishL10n.socialAuthNetworkError,
          equals(
            'Falló la conexión de red. Por favor verifica tu conexión a '
            'internet e intenta de nuevo.',
          ),
        );
        expect(
          spanishL10n.socialAuthTimeout,
          equals('La autenticación expiró. Por favor intenta de nuevo.'),
        );
        expect(
          spanishL10n.accountLinkingError,
          equals(
            'No se pudo vincular tu cuenta. Por favor intenta de nuevo o '
            'contacta soporte.',
          ),
        );
        expect(
          spanishL10n.cancelProfileSetup,
          equals('Cancelar configuración'),
        );
        expect(
          spanishL10n.cancelProfileSetupMessage,
          equals(
            '¿Estás seguro de que quieres cancelar? Serás desconectado y '
            'necesitarás iniciar sesión de nuevo.',
          ),
        );
        expect(spanishL10n.continueSetup, equals('Continuar configuración'));
        expect(
          spanishL10n.signInWithEmail,
          equals('Iniciar sesión con correo'),
        );
        expect(
          spanishL10n.linkAccountBenefit,
          equals(
            'Esto te permitirá iniciar sesión con cualquiera de los dos '
            'métodos.',
          ),
        );
      });

      test('should handle parameterized strings', () {
        expect(
          spanishL10n.accountExistsMessage('test@example.com'),
          equals('Ya existe una cuenta con el correo test@example.com.'),
        );
        expect(
          spanishL10n.linkAccountQuestion('Google'),
          equals(
            '¿Te gustaría vincular tu cuenta de Google con tu cuenta '
            'existente?',
          ),
        );
        expect(
          spanishL10n.linkAccountQuestion('Apple'),
          equals(
            '¿Te gustaría vincular tu cuenta de Apple con tu cuenta existente?',
          ),
        );
      });
    });

    group('Arabic Localization', () {
      test('should have all social login strings', () {
        expect(arabicL10n.continueWithGoogle, equals('المتابعة مع Google'));
        expect(arabicL10n.continueWithApple, equals('المتابعة مع Apple'));
        expect(arabicL10n.or, equals('أو'));
        expect(arabicL10n.completeYourProfile, equals('أكمل ملفك الشخصي'));
        expect(
          arabicL10n.profileSetupDescription,
          equals('يرجى إكمال ملفك الشخصي للبدء في استخدام Grex'),
        );
        expect(arabicL10n.linkYourAccount, equals('ربط حسابك'));
        expect(arabicL10n.linkAccounts, equals('ربط الحسابات'));
        expect(arabicL10n.createNewAccount, equals('إنشاء حساب جديد'));
        expect(
          arabicL10n.socialAuthFailed,
          equals('فشل في المصادقة. يرجى المحاولة مرة أخرى.'),
        );
        expect(
          arabicL10n.socialAuthNetworkError,
          equals(
            'فشل في الاتصال بالشبكة. يرجى التحقق من اتصالك بالإنترنت '
            'والمحاولة مرة أخرى.',
          ),
        );
        expect(
          arabicL10n.socialAuthTimeout,
          equals('انتهت مهلة المصادقة. يرجى المحاولة مرة أخرى.'),
        );
        expect(
          arabicL10n.accountLinkingError,
          equals('فشل في ربط حسابك. يرجى المحاولة مرة أخرى أو الاتصال بالدعم.'),
        );
        expect(arabicL10n.cancelProfileSetup, equals('إلغاء الإعداد'));
        expect(
          arabicL10n.cancelProfileSetupMessage,
          equals(
            'هل أنت متأكد أنك تريد الإلغاء؟ سيتم تسجيل خروجك وستحتاج إلى '
            'تسجيل الدخول مرة أخرى.',
          ),
        );
        expect(arabicL10n.continueSetup, equals('متابعة الإعداد'));
        expect(
          arabicL10n.signInWithEmail,
          equals('تسجيل الدخول بالبريد الإلكتروني'),
        );
        expect(
          arabicL10n.linkAccountBenefit,
          equals('سيسمح لك هذا بتسجيل الدخول بأي من الطريقتين.'),
        );
      });

      test('should handle parameterized strings', () {
        expect(
          arabicL10n.accountExistsMessage('test@example.com'),
          equals('يوجد حساب بالبريد الإلكتروني test@example.com بالفعل.'),
        );
        expect(
          arabicL10n.linkAccountQuestion('Google'),
          equals('هل تريد ربط حساب Google الخاص بك بحسابك الحالي؟'),
        );
        expect(
          arabicL10n.linkAccountQuestion('Apple'),
          equals('هل تريد ربط حساب Apple الخاص بك بحسابك الحالي؟'),
        );
      });
    });

    group('Cross-Language Validation', () {
      test('should have consistent parameter handling across languages', () {
        const testEmail = 'user@example.com';
        const testProvider = 'Google';

        // Test that all languages handle parameters correctly
        final languages = [
          ('English', englishL10n),
          ('Vietnamese', vietnameseL10n),
          ('Spanish', spanishL10n),
          ('Arabic', arabicL10n),
        ];

        for (final (languageName, l10n) in languages) {
          final accountMessage = l10n.accountExistsMessage(testEmail);
          final linkMessage = l10n.linkAccountQuestion(testProvider);

          expect(
            accountMessage.contains(testEmail),
            isTrue,
            reason:
                '$languageName should contain email in accountExistsMessage',
          );
          expect(
            accountMessage.contains('{email}'),
            isFalse,
            reason:
                '$languageName should not contain placeholder in '
                'accountExistsMessage',
          );

          expect(
            linkMessage.contains(testProvider),
            isTrue,
            reason:
                '$languageName should contain provider in linkAccountQuestion',
          );
          expect(
            linkMessage.contains('{provider}'),
            isFalse,
            reason:
                '$languageName should not contain placeholder in '
                'linkAccountQuestion',
          );
        }
      });

      test('should have non-empty strings in all languages', () {
        final stringGetters = [
          (AppLocalizations l10n) => l10n.continueWithGoogle,
          (AppLocalizations l10n) => l10n.continueWithApple,
          (AppLocalizations l10n) => l10n.or,
          (AppLocalizations l10n) => l10n.completeYourProfile,
          (AppLocalizations l10n) => l10n.profileSetupDescription,
          (AppLocalizations l10n) => l10n.linkYourAccount,
          (AppLocalizations l10n) => l10n.linkAccounts,
          (AppLocalizations l10n) => l10n.createNewAccount,
          (AppLocalizations l10n) => l10n.socialAuthFailed,
          (AppLocalizations l10n) => l10n.socialAuthNetworkError,
          (AppLocalizations l10n) => l10n.socialAuthTimeout,
          (AppLocalizations l10n) => l10n.accountLinkingError,
          (AppLocalizations l10n) => l10n.cancelProfileSetup,
          (AppLocalizations l10n) => l10n.cancelProfileSetupMessage,
          (AppLocalizations l10n) => l10n.continueSetup,
          (AppLocalizations l10n) => l10n.signInWithEmail,
          (AppLocalizations l10n) => l10n.linkAccountBenefit,
        ];

        final languages = [
          ('English', englishL10n),
          ('Vietnamese', vietnameseL10n),
          ('Spanish', spanishL10n),
          ('Arabic', arabicL10n),
        ];

        for (final (languageName, l10n) in languages) {
          for (var i = 0; i < stringGetters.length; i++) {
            final stringValue = stringGetters[i](l10n);
            expect(
              stringValue.trim().isNotEmpty,
              isTrue,
              reason: '$languageName string at index $i should not be empty',
            );
          }
        }
      });

      test('should have different translations for non-English languages', () {
        final stringGetters = [
          (AppLocalizations l10n) => l10n.or,
          (AppLocalizations l10n) => l10n.completeYourProfile,
          (AppLocalizations l10n) => l10n.linkYourAccount,
          (AppLocalizations l10n) => l10n.linkAccounts,
          (AppLocalizations l10n) => l10n.createNewAccount,
          (AppLocalizations l10n) => l10n.socialAuthFailed,
          (AppLocalizations l10n) => l10n.cancelProfileSetup,
          (AppLocalizations l10n) => l10n.continueSetup,
          (AppLocalizations l10n) => l10n.signInWithEmail,
        ];

        final nonEnglishLanguages = [
          ('Vietnamese', vietnameseL10n),
          ('Spanish', spanishL10n),
          ('Arabic', arabicL10n),
        ];

        for (final (languageName, l10n) in nonEnglishLanguages) {
          for (var i = 0; i < stringGetters.length; i++) {
            final englishValue = stringGetters[i](englishL10n);
            final translatedValue = stringGetters[i](l10n);

            expect(
              translatedValue,
              isNot(equals(englishValue)),
              reason:
                  '$languageName string at index $i should be different '
                  'from English',
            );
          }
        }
      });
    });
  });
}

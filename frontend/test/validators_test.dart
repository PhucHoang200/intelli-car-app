import 'package:flutter_test/flutter_test.dart';
import 'package:online_car_marketplace_app/utils/validators/auth_validator.dart';
import 'package:online_car_marketplace_app/utils/validators/car_validator.dart';
import 'package:online_car_marketplace_app/utils/validators/post_validator.dart';
import 'package:online_car_marketplace_app/utils/validators/user_validator.dart';

void main() {
  group('Authentication input boundaries', () {
    for (final value in <String?>[null, '', 'plain', 'a@', '@example.com']) {
      test('reject invalid email: $value', () {
        expect(AuthValidator.validateEmail(value), isNotNull);
      });
    }
    test('accept ordinary email', () {
      expect(AuthValidator.validateEmail('buyer@example.com'), isNull);
    });
    for (final value in <String?>[
      null,
      '',
      'Ab1!xyz',
      'abcdefgh',
      '12345678'
    ]) {
      test('reject invalid password: $value', () {
        expect(AuthValidator.validatePassword(value), isNotNull);
      });
    }
    test('accept password at eight-character boundary', () {
      expect(AuthValidator.validatePassword('Abcdef1!'), isNull);
    });
    for (final value in <String?>[
      null,
      '',
      '1234567890',
      '012345678',
      '01234567890',
      '0abcdefghi'
    ]) {
      test('reject invalid phone: $value', () {
        expect(AuthValidator.validatePhone(value), isNotNull);
      });
    }
    test('accept ten-digit phone starting with zero', () {
      expect(AuthValidator.validatePhone('0912345678'), isNull);
    });
    test('confirmation requires matching nonempty password', () {
      expect(
          AuthValidator.validateConfirmPassword(null, 'Abcdef1!'), isNotNull);
      expect(AuthValidator.validateConfirmPassword('', 'Abcdef1!'), isNotNull);
      expect(AuthValidator.validateConfirmPassword('different', 'Abcdef1!'),
          isNotNull);
      expect(AuthValidator.validateConfirmPassword('Abcdef1!', 'Abcdef1!'),
          isNull);
    });
    test('required field rejects absent values', () {
      expect(AuthValidator.validateRequired(null, 'Name'), isNotNull);
      expect(AuthValidator.validateRequired('', 'Name'), isNotNull);
      expect(AuthValidator.validateRequired('Buyer', 'Name'), isNull);
    });
  });

  group('Car validation regressions', () {
    for (final value in ['Tự động', 'Số sàn', 'tự động', 'số sàn']) {
      test('accept supported transmission $value', () {
        expect(CarValidator.validateTransmission(value), value);
      });
    }
    for (final value in [
      'Xăng',
      'Dầu',
      'Điện',
      'Hybrid',
      'xăng',
      'dầu',
      'điện',
      'hybrid'
    ]) {
      test('accept supported fuel $value', () {
        expect(CarValidator.validateFuelType(value), value);
      });
    }
    test('reject unsupported fuel and transmission', () {
      expect(() => CarValidator.validateFuelType('unknown'), throwsException);
      expect(
          () => CarValidator.validateTransmission('unknown'), throwsException);
    });
    test('license plate accepts documented examples', () {
      expect(CarValidator.validateLicensePlate('30F25658'), '30F25658');
      expect(CarValidator.validateLicensePlate('36F0987'), '36F0987');
    });
    test('reject malformed plate and blank location', () {
      expect(
          () => CarValidator.validateLicensePlate('invalid'), throwsException);
      expect(() => CarValidator.validateLocation('   '), throwsException);
      expect(CarValidator.validateLocation('Hà Nội'), 'Hà Nội');
    });
  });

  group('User and moderation boundaries', () {
    test('trim name and enforce one through fifty characters', () {
      expect(UserValidator.validateName('  An  '), 'An');
      expect(UserValidator.validateName('A' * 50), 'A' * 50);
      expect(() => UserValidator.validateName(' '), throwsException);
      expect(() => UserValidator.validateName('A' * 51), throwsException);
    });
    test('accept known user states; reject unknown state', () {
      for (final status in ['Hoạt động', 'Khóa', 'Chờ xác thực']) {
        expect(UserValidator.validateStatus(status), status);
      }
      expect(() => UserValidator.validateStatus('unknown'), throwsException);
    });
    test('accept moderation states and default pending state', () {
      for (final status in ['Chờ duyệt', 'Đã duyệt', 'Từ chối']) {
        expect(PostValidator.validateStatus(status), status);
      }
      expect(PostValidator.defaultStatus, 'Chờ duyệt');
      expect(() => PostValidator.validateStatus('unknown'), throwsException);
    });
  });
}

import 'package:sms_sender_background/sms_sender.dart';

class SmsFallbackService {
  static final SmsSender _smsSender = SmsSender();

  static Future<bool> sendEmergencySms({
    required String phoneNumber,
    required String emergencyType,
    required double latitude,
    required double longitude,
    required int victims,
  }) async {
    try {
      print('Checking SMS permission...');

      bool hasPermission =
          await _smsSender.checkSmsPermission();

      print('SMS permission: $hasPermission');

      if (!hasPermission) {
        hasPermission =
            await _smsSender.requestSmsPermission();

        print(
          'SMS permission after request: $hasPermission',
        );
      }

      if (!hasPermission) {
        print('SMS permission denied');
        return false;
      }

      final message =
          '$emergencyType | '
          '${latitude.toStringAsFixed(4)},'
          '${longitude.toStringAsFixed(4)} | '
          '$victims VICTIMS';

      print('Sending emergency SMS...');

      // Do NOT request phone-state permission here.
      // The plugin can fall back to the default SIM.
      final success = await _smsSender.sendSms(
        phoneNumber: phoneNumber,
        message: message,
      );

      print('SMS send result: $success');

      return success;
    } catch (e) {
      print('Emergency SMS failed: $e');
      return false;
    }
  }
}
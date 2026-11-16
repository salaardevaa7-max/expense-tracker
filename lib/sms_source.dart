// ===========================================================================
//  Reading SMS using flutter_sms_inbox.
// ===========================================================================

import 'dart:io' show Platform;
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

import 'sms_parser.dart';

class SmsSource {
  static bool get supported => Platform.isAndroid;

  static const String unavailableReason =
      'Reading messages only works on Android. Apple does not let any app '
      'see your SMS inbox, so on iPhone you would add expenses by hand.';

  static Future<bool> request() async {
    if (!supported) return false;
    try {
      final status = await Permission.sms.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> granted() async {
    if (!supported) return false;
    try {
      return await Permission.sms.isGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> permanentlyDenied() async {
    if (!supported) return false;
    try {
      return await Permission.sms.isPermanentlyDenied;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openSettings() => openAppSettings();

  static Future<List<RawSms>> recent({int days = 45}) async {
    if (!supported) return const [];
    if (!await granted()) return const [];

    try {
      final query = SmsQuery();
      final messages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 200,
      );

      final cutoff = DateTime.now()
          .subtract(Duration(days: days))
          .millisecondsSinceEpoch;

      final out = <RawSms>[];
      for (final m in messages) {
        final body = m.body;
        if (body == null || body.isEmpty) continue;
        final at = m.date?.millisecondsSinceEpoch;
        if (at != null && at < cutoff) continue;
        out.add(RawSms(
          body: body,
          sender: m.address ?? '',
          id: m.id,
          at: at,
        ));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }
}

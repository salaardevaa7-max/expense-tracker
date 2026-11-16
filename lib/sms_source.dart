// ===========================================================================
//  The only file in the app that knows an SMS plugin exists.
//
//  It is isolated on purpose. `another_telephony` is the least predictable
//  dependency here — Android-only, and it wraps a permission Google treats
//  as restricted. If it ever fails to build, this one file gets swapped for
//  sms_source_stub.dart and everything else carries on unchanged; the parser,
//  the confirm screen and the ledger have no idea which one they are talking
//  to.
//
//  The API surface used below is one call with no arguments, which is the
//  narrowest thing that could possibly work — and therefore the least likely
//  to break when the package changes.
// ===========================================================================

import 'dart:io' show Platform;

import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

import 'sms_parser.dart';

class SmsSource {
  /// iOS gives no application any way to read the SMS inbox — not with a
  /// permission, not with entitlement, not at all. So on iPhone this feature
  /// is honestly absent rather than pretending and failing.
  static bool get supported => Platform.isAndroid;

  static const String unavailableReason =
      'Reading messages only works on Android. Apple does not let any app '
      'see your SMS inbox, so on iPhone you would add expenses by hand.';

  /// Asks for the permission. Returns false if the person says no, or says
  /// "never ask again", in which case the caller should send them to Settings.
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

  /// Everything in the inbox from the last [days] days, newest first.
  ///
  /// Filtering by date is done here in Dart rather than in the query, because
  /// the plugin's filter API has changed shape between versions and a date
  /// comparison on a few hundred rows costs nothing.
  static Future<List<RawSms>> recent({int days = 45}) async {
    if (!supported) return const [];
    if (!await granted()) return const [];

    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;

    try {
      final messages = await Telephony.instance.getInboxSms();
      final out = <RawSms>[];
      for (final m in messages) {
        final body = m.body;
        if (body == null || body.isEmpty) continue;
        final at = m.date;
        if (at != null && at < cutoff) continue;
        out.add(RawSms(
          body: body,
          sender: m.address ?? '',
          id: m.id,
          at: at,
        ));
      }
      out.sort((a, b) => (b.at ?? 0).compareTo(a.at ?? 0));
      return out;
    } catch (_) {
      // A plugin that throws should cost you the feature, never the app.
      return const [];
    }
  }
}

// ===========================================================================
//  The escape hatch.
//
//  If the build ever fails on `another_telephony`, do two things:
//
//    1. delete the `another_telephony: any` line from pubspec.yaml
//    2. copy this file over lib/sms_source.dart
//
//  The app then builds and runs with every other feature intact. Automatic
//  capture goes quiet and says so; the "Paste a message" box on the Capture
//  screen still works, and it uses exactly the same parser, so you can test
//  that the reading of bank SMS is correct even without the plugin.
//
//  This file must keep the same public shape as the real one. If you change
//  one, change both.
// ===========================================================================

import 'sms_parser.dart';

class SmsSource {
  static bool get supported => false;

  static const String unavailableReason =
      'Automatic message reading is switched off in this build. You can still '
      'paste a bank message in below and Hisaab will read it the same way.';

  static Future<bool> request() async => false;

  static Future<bool> granted() async => false;

  static Future<bool> permanentlyDenied() async => false;

  static Future<void> openSettings() async {}

  static Future<List<RawSms>> recent({int days = 45}) async => const [];
}

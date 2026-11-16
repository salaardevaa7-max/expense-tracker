// ===========================================================================
//  Google Drive Cloud Backup.
//
//  This allows Hisaab to automatically backup your local SQLite database to
//  a private, hidden "App Data" folder on your Google Drive.
//
//  It uses the Google Drive API to ensure your data is always safe, even if
//  you lose your phone or uninstall the app.
// ===========================================================================

import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class Cloud {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  static GoogleSignInAccount? _user;

  static Future<bool> signIn() async {
    try {
      _user = await _googleSignIn.signIn();
      return _user != null;
    } catch (e) {
      print('Sign-In Error: $e');
      return false;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    _user = null;
  }

  static bool get isSignedIn => _user != null;
  static String? get userEmail => _user?.email;

  /// Uploads the local hisaab.db file to Google Drive.
  static Future<bool> backup() async {
    final user = _user;
    if (user == null) return false;

    try {
      final authHeaders = await user.authHeaders;
      final client = _GoogleHttpClient(authHeaders);
      final api = drive.DriveApi(client);

      // 1. Find existing backup file in the appDataFolder
      final fileList = await api.files.list(
        spaces: 'appDataFolder',
        q: "name = 'hisaab_backup.db'",
      );

      final dir = await getDatabasesPath();
      final dbFile = File(p.join(dir, 'hisaab.db'));
      if (!await dbFile.exists()) return false;

      final media = drive.Media(dbFile.openRead(), await dbFile.length());
      final driveFile = drive.File()..name = 'hisaab_backup.db';

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Update existing
        final existingId = fileList.files!.first.id!;
        await api.files.update(driveFile, existingId, uploadMedia: media);
        print('Updated cloud backup: $existingId');
      } else {
        // Create new
        driveFile.parents = ['appDataFolder'];
        final created = await api.files.create(driveFile, uploadMedia: media);
        print('Created new cloud backup: ${created.id}');
      }

      return true;
    } catch (e) {
      print('Backup Error: $e');
      return false;
    }
  }

  /// Downloads the hisaab_backup.db file from Google Drive and replaces the local one.
  static Future<bool> restore() async {
    final user = _user;
    if (user == null) return false;

    try {
      final authHeaders = await user.authHeaders;
      final client = _GoogleHttpClient(authHeaders);
      final api = drive.DriveApi(client);

      final fileList = await api.files.list(
        spaces: 'appDataFolder',
        q: "name = 'hisaab_backup.db'",
      );

      if (fileList.files == null || fileList.files!.isEmpty) return false;
      final driveId = fileList.files!.first.id!;

      final response = await api.files.get(driveId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

      final dir = await getDatabasesPath();
      final localPath = p.join(dir, 'hisaab.db');

      // We must close the DB connection before replacing the file.
      // Call Db.i.close() from the UI before calling restore.
      final file = File(localPath);
      final sink = file.openWrite();
      await sink.addStream(response.stream);
      await sink.close();

      return true;
    } catch (e) {
      print('Restore Error: $e');
      return false;
    }
  }
}

/// Simple HTTP client that attaches Google Auth headers to every request.
class _GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

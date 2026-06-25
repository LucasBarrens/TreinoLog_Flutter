import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/index.dart';
import 'database_service.dart';

class BackupService {
  static const _autoBackupIntervalDays = 1;
  static const _maxAutoBackups = 7;

  static Future<void> exportAndShareBackup() async {
    final file = await _writeBackupFile(prefix: 'manual');

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Backup GymLog',
    );
  }

  static Future<void> importJsonBackup(File file) async {
    final content = await file.readAsString();
    final payload = json.decode(content) as Map<String, dynamic>;

    final workoutTemplates = (payload['workoutTemplates'] as List<dynamic>? ?? [])
        .map((e) => WorkoutTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
    final exerciseTemplates = (payload['exerciseTemplates'] as List<dynamic>? ?? [])
        .map((e) => ExerciseTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
    final workoutSessions = (payload['workoutSessions'] as List<dynamic>? ?? [])
        .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
        .toList();
    final exerciseLogs = (payload['exerciseLogs'] as List<dynamic>? ?? [])
        .map((e) => ExerciseLog.fromJson(e as Map<String, dynamic>))
        .toList();
    final setLogs = (payload['setLogs'] as List<dynamic>? ?? [])
        .map((e) => SetLog.fromJson(e as Map<String, dynamic>))
        .toList();

    // Safety net: snapshot current data before replacing, so a corrupt import
    // payload can still be recovered from disk.
    await _writeBackupFile(prefix: 'pre-import');

    await DatabaseService.replaceAllData(
      workoutTemplates: workoutTemplates,
      exerciseTemplates: exerciseTemplates,
      workoutSessions: workoutSessions,
      exerciseLogs: exerciseLogs,
      setLogs: setLogs,
    );
  }

  // Runs once a day on app startup. Writes a JSON snapshot without sharing.
  static Future<void> runAutoDailyBackupIfNeeded() async {
    final lastAuto = await _readAutoBackupAt();
    if (lastAuto != null) {
      final elapsed = DateTime.now().difference(lastAuto);
      if (elapsed.inDays < _autoBackupIntervalDays) {
        return;
      }
    }

    try {
      await _writeBackupFile(prefix: 'auto');
      await _writeAutoBackupAt(DateTime.now());
      await _pruneAutoBackups();
    } catch (_) {
      // Auto-backup is best-effort. Never break app startup.
    }
  }

  // ---- internals ----

  static Future<Directory> _backupDir() async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  static Future<File> _writeBackupFile({required String prefix}) async {
    final backupDir = await _backupDir();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${backupDir.path}/gymlog-$prefix-$timestamp.json');
    final payload = await _buildPayload();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file;
  }

  static Future<void> _pruneAutoBackups() async {
    final backupDir = await _backupDir();
    final autoFiles = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('/gymlog-auto-'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));

    for (var i = _maxAutoBackups; i < autoFiles.length; i++) {
      try {
        await autoFiles[i].delete();
      } catch (_) {}
    }
  }

  static Future<File> _statusFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/backup_status.json');
  }

  static Future<Map<String, dynamic>> _readStatus() async {
    final file = await _statusFile();
    if (!await file.exists()) return {};
    try {
      return json.decode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeStatus(Map<String, dynamic> status) async {
    final file = await _statusFile();
    await file.writeAsString(json.encode(status));
  }

  static Future<DateTime?> _readAutoBackupAt() async {
    final status = await _readStatus();
    final raw = status['lastAutoBackupAt'] as String?;
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static Future<void> _writeAutoBackupAt(DateTime when) async {
    final status = await _readStatus();
    status['lastAutoBackupAt'] = when.toIso8601String();
    await _writeStatus(status);
  }

  static Future<Map<String, dynamic>> _buildPayload() async {
    final workouts = await DatabaseService.getWorkoutTemplates();
    final workoutSessions = await DatabaseService.getWorkoutSessions();

    final exerciseTemplates = <ExerciseTemplate>[];
    final exerciseLogs = <ExerciseLog>[];
    final setLogs = <SetLog>[];

    for (final workout in workouts) {
      exerciseTemplates.addAll(
        await DatabaseService.getExerciseTemplates(workout.name),
      );
    }

    for (final session in workoutSessions) {
      final logs = await DatabaseService.getExerciseLogsBySession(session.id);
      exerciseLogs.addAll(logs);

      for (final log in logs) {
        setLogs.addAll(
          await DatabaseService.getSetLogsByExercise(log.id),
        );
      }
    }

    return {
      'app': 'GymLog',
      'exportedAt': DateTime.now().toIso8601String(),
      'workoutTemplates': workouts.map((e) => e.toJson()).toList(),
      'exerciseTemplates': exerciseTemplates.map((e) => e.toJson()).toList(),
      'workoutSessions': workoutSessions.map((e) => e.toJson()).toList(),
      'exerciseLogs': exerciseLogs.map((e) => e.toJson()).toList(),
      'setLogs': setLogs.map((e) => e.toJson()).toList(),
    };
  }
}

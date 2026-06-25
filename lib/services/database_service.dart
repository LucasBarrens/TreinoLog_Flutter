import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/index.dart';

class DatabaseService {
  // Kept as treinolog.db on disk so existing installs keep their data after
  // the rebrand to GymLog. Don't change without writing a migration.
  static const _databaseName = 'treinolog.db';
  static const _databaseVersion = 4;

  static Database? _database;

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workout_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        order_index INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        exercise_key TEXT,
        workout_template_id TEXT,
        workout_name TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        default_rep_range TEXT,
        default_notes TEXT,
        FOREIGN KEY (workout_template_id) REFERENCES workout_templates(id),
        FOREIGN KEY (workout_name) REFERENCES workout_templates(name)
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_sessions (
        id TEXT PRIMARY KEY,
        workout_template_id TEXT,
        workout_name TEXT NOT NULL,
        date TEXT NOT NULL,
        finished_at TEXT,
        notes TEXT,
        is_finished INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (workout_template_id) REFERENCES workout_templates(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_logs (
        id TEXT PRIMARY KEY,
        exercise_name TEXT NOT NULL,
        exercise_key TEXT,
        order_index INTEGER NOT NULL,
        notes TEXT,
        rep_range TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        workout_session_id TEXT,
        FOREIGN KEY (workout_session_id) REFERENCES workout_sessions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE set_logs (
        id TEXT PRIMARY KEY,
        set_number INTEGER NOT NULL,
        weight_kg REAL NOT NULL DEFAULT 0,
        reps INTEGER NOT NULL DEFAULT 0,
        note TEXT,
        effort_type TEXT DEFAULT 'none',
        exercise_log_id TEXT,
        FOREIGN KEY (exercise_log_id) REFERENCES exercise_logs(id) ON DELETE CASCADE
      )
    ''');

    await _createBodyMeasurementsTable(db);
  }

  static Future<void> _createBodyMeasurementsTable(Database db) async {
    await db.execute('''
      CREATE TABLE body_measurements (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        sex TEXT NOT NULL DEFAULT 'unspecified',
        weight_kg REAL,
        height_cm REAL,
        biceps_right_cm REAL,
        biceps_left_cm REAL,
        chest_cm REAL,
        waist_cm REAL,
        abdomen_cm REAL,
        hip_cm REAL,
        glutes_cm REAL,
        thigh_right_cm REAL,
        thigh_left_cm REAL,
        calf_right_cm REAL,
        calf_left_cm REAL,
        notes TEXT
      )
    ''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Add workoutTemplateId column to exercise_templates
      await db.execute('''
        ALTER TABLE exercise_templates
        ADD COLUMN workout_template_id TEXT
      ''');

      // Add workoutTemplateId column to workout_sessions
      await db.execute('''
        ALTER TABLE workout_sessions
        ADD COLUMN workout_template_id TEXT
      ''');

      // Backfill workoutTemplateId using workoutName lookup
      await _backfillTemplateIds(db);
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE exercise_logs ADD COLUMN rep_range TEXT');
    }
  }

  static Future<void> _backfillTemplateIds(Database db) async {
    // Backfill exercise_templates
    final exerciseRows = await db.query('exercise_templates');
    for (final row in exerciseRows) {
      final workoutName = row['workout_name'] as String?;
      if (workoutName != null && workoutName.isNotEmpty) {
        final templates = await db.query(
          'workout_templates',
          where: 'name = ?',
          whereArgs: [workoutName],
        );
        if (templates.isNotEmpty) {
          await db.update(
            'exercise_templates',
            {'workout_template_id': templates.first['id']},
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
      }
    }

    // Backfill workout_sessions
    final sessionRows = await db.query('workout_sessions');
    for (final row in sessionRows) {
      final workoutName = row['workout_name'] as String?;
      if (workoutName != null && workoutName.isNotEmpty) {
        final templates = await db.query(
          'workout_templates',
          where: 'name = ?',
          whereArgs: [workoutName],
        );
        if (templates.isNotEmpty) {
          await db.update(
            'workout_sessions',
            {'workout_template_id': templates.first['id']},
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
      }
    }
  }

  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('set_logs');
    await db.delete('exercise_logs');
    await db.delete('workout_sessions');
    await db.delete('exercise_templates');
    await db.delete('workout_templates');
  }

  // Atomic replace of all data. Either every row is replaced or the original
  // data stays intact — used by backup import so a crash mid-restore can't
  // wipe history.
  static Future<void> replaceAllData({
    required List<WorkoutTemplate> workoutTemplates,
    required List<ExerciseTemplate> exerciseTemplates,
    required List<WorkoutSession> workoutSessions,
    required List<ExerciseLog> exerciseLogs,
    required List<SetLog> setLogs,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('set_logs');
      await txn.delete('exercise_logs');
      await txn.delete('workout_sessions');
      await txn.delete('exercise_templates');
      await txn.delete('workout_templates');

      final batch = txn.batch();

      for (final t in workoutTemplates) {
        batch.insert('workout_templates', {
          'id': t.id,
          'name': t.name,
          'order_index': t.order,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (final t in exerciseTemplates) {
        batch.insert('exercise_templates', {
          'id': t.id,
          'name': t.name,
          'exercise_key': t.exerciseKey,
          'workout_template_id': t.workoutTemplateId,
          'workout_name': t.workoutName,
          'order_index': t.order,
          'default_rep_range': t.defaultRepRange,
          'default_notes': t.defaultNotes,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (final s in workoutSessions) {
        batch.insert('workout_sessions', {
          'id': s.id,
          'workout_template_id': s.workoutTemplateId,
          'workout_name': s.workoutName,
          'date': s.date.toIso8601String(),
          'finished_at': s.finishedAt?.toIso8601String(),
          'notes': s.notes,
          'is_finished': s.isFinished ? 1 : 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (final l in exerciseLogs) {
        batch.insert('exercise_logs', {
          'id': l.id,
          'exercise_name': l.exerciseName,
          'exercise_key': l.exerciseKey,
          'order_index': l.order,
          'notes': l.notes,
          'rep_range': l.repRange,
          'is_completed': l.isCompleted ? 1 : 0,
          'workout_session_id': l.workoutSessionId,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (final s in setLogs) {
        batch.insert('set_logs', {
          'id': s.id,
          'set_number': s.setNumber,
          'weight_kg': s.weightKg,
          'reps': s.reps,
          'note': s.note,
          'effort_type': s.effortType.dbValue,
          'exercise_log_id': s.exerciseLogId,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
    });
  }

  // Workout Templates
  static Future<void> insertWorkoutTemplate(WorkoutTemplate template) async {
    final db = await database;
    await db.insert(
      'workout_templates',
      {
        'id': template.id,
        'name': template.name,
        'order_index': template.order,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<WorkoutTemplate>> getWorkoutTemplates() async {
    final db = await database;
    final result = await db.query(
      'workout_templates',
      orderBy: 'order_index ASC',
    );
    return result.map((row) {
      return WorkoutTemplate(
        id: row['id'] as String,
        name: row['name'] as String,
        order: row['order_index'] as int,
      );
    }).toList();
  }

  static Future<void> updateWorkoutTemplate(WorkoutTemplate template) async {
    final db = await database;
    await db.update(
      'workout_templates',
      {
        'name': template.name,
        'order_index': template.order,
      },
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  static Future<void> deleteWorkoutTemplate(String id) async {
    final db = await database;
    await db.delete(
      'workout_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Exercise Templates
  static Future<void> insertExerciseTemplate(ExerciseTemplate template) async {
    final db = await database;
    await db.insert(
      'exercise_templates',
      {
        'id': template.id,
        'name': template.name,
        'exercise_key': template.exerciseKey,
        'workout_template_id': template.workoutTemplateId,
        'workout_name': template.workoutName,
        'order_index': template.order,
        'default_rep_range': template.defaultRepRange,
        'default_notes': template.defaultNotes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ExerciseTemplate>> getExerciseTemplates(
    String workoutName,
  ) async {
    final db = await database;
    final result = await db.query(
      'exercise_templates',
      where: 'workout_name = ?',
      whereArgs: [workoutName],
      orderBy: 'order_index ASC',
    );
    return result.map((row) {
      return ExerciseTemplate(
        id: row['id'] as String,
        name: row['name'] as String,
        exerciseKey: row['exercise_key'] as String?,
        workoutTemplateId: row['workout_template_id'] as String? ?? '',
        workoutName: row['workout_name'] as String,
        order: row['order_index'] as int,
        defaultRepRange: row['default_rep_range'] as String? ?? '',
        defaultNotes: row['default_notes'] as String? ?? '',
      );
    }).toList();
  }

  static Future<void> updateExerciseTemplate(ExerciseTemplate template) async {
    final db = await database;
    await db.update(
      'exercise_templates',
      {
        'name': template.name,
        'exercise_key': template.exerciseKey,
        'order_index': template.order,
        'default_rep_range': template.defaultRepRange,
        'default_notes': template.defaultNotes,
      },
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  static Future<void> deleteExerciseTemplate(String id) async {
    final db = await database;
    await db.delete(
      'exercise_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Workout Sessions
  static Future<void> insertWorkoutSession(WorkoutSession session) async {
    final db = await database;
    await db.insert(
      'workout_sessions',
      {
        'id': session.id,
        'workout_template_id': session.workoutTemplateId,
        'workout_name': session.workoutName,
        'date': session.date.toIso8601String(),
        'finished_at': session.finishedAt?.toIso8601String(),
        'notes': session.notes,
        'is_finished': session.isFinished ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<WorkoutSession>> getWorkoutSessions() async {
    final db = await database;
    final result = await db.query(
      'workout_sessions',
      orderBy: 'date DESC',
    );
    return result.map((row) {
      return WorkoutSession(
        id: row['id'] as String,
        workoutTemplateId: row['workout_template_id'] as String? ?? '',
        workoutName: row['workout_name'] as String,
        date: DateTime.parse(row['date'] as String),
        finishedAt: row['finished_at'] != null
            ? DateTime.parse(row['finished_at'] as String)
            : null,
        notes: row['notes'] as String? ?? '',
        isFinished: (row['is_finished'] as int? ?? 0) == 1,
      );
    }).toList();
  }

  static Future<void> updateWorkoutSession(WorkoutSession session) async {
    final db = await database;
    await db.update(
      'workout_sessions',
      {
        'date': session.date.toIso8601String(),
        'finished_at': session.finishedAt?.toIso8601String(),
        'notes': session.notes,
        'is_finished': session.isFinished ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  static Future<void> deleteWorkoutSession(String id) async {
    final db = await database;
    await db.delete(
      'workout_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Exercise Logs
  static Future<void> insertExerciseLog(ExerciseLog log) async {
    final db = await database;
    await db.insert(
      'exercise_logs',
      {
        'id': log.id,
        'exercise_name': log.exerciseName,
        'exercise_key': log.exerciseKey,
        'order_index': log.order,
        'notes': log.notes,
        'rep_range': log.repRange,
        'is_completed': log.isCompleted ? 1 : 0,
        'workout_session_id': log.workoutSessionId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ExerciseLog>> getExerciseLogsBySession(
    String sessionId,
  ) async {
    final db = await database;
    final result = await db.query(
      'exercise_logs',
      where: 'workout_session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'order_index ASC',
    );
    return result.map((row) {
      return ExerciseLog(
        id: row['id'] as String,
        exerciseName: row['exercise_name'] as String,
        exerciseKey: row['exercise_key'] as String? ?? '',
        order: row['order_index'] as int,
        notes: row['notes'] as String? ?? '',
        repRange: row['rep_range'] as String? ?? '',
        isCompleted: (row['is_completed'] as int? ?? 0) == 1,
        workoutSessionId: row['workout_session_id'] as String?,
      );
    }).toList();
  }

  static Future<void> updateExerciseLog(ExerciseLog log) async {
    final db = await database;
    await db.update(
      'exercise_logs',
      {
        'exercise_name': log.exerciseName,
        'exercise_key': log.exerciseKey,
        'order_index': log.order,
        'notes': log.notes,
        'rep_range': log.repRange,
        'is_completed': log.isCompleted ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  static Future<void> deleteExerciseLog(String id) async {
    final db = await database;
    await db.delete(
      'exercise_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Set Logs
  static Future<void> insertSetLog(SetLog log) async {
    final db = await database;
    await db.insert(
      'set_logs',
      {
        'id': log.id,
        'set_number': log.setNumber,
        'weight_kg': log.weightKg,
        'reps': log.reps,
        'note': log.note,
        'effort_type': log.effortType.dbValue,
        'exercise_log_id': log.exerciseLogId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<SetLog>> getSetLogsByExercise(String exerciseLogId) async {
    final db = await database;
    final result = await db.query(
      'set_logs',
      where: 'exercise_log_id = ?',
      whereArgs: [exerciseLogId],
      orderBy: 'set_number ASC',
    );
    return result.map((row) {
      return SetLog(
        id: row['id'] as String,
        setNumber: row['set_number'] as int,
        weightKg: (row['weight_kg'] as num? ?? 0).toDouble(),
        reps: row['reps'] as int? ?? 0,
        note: row['note'] as String? ?? '',
        effortType: effortTypeFromDbValue(row['effort_type'] as String? ?? 'none'),
        exerciseLogId: row['exercise_log_id'] as String?,
      );
    }).toList();
  }

  static Future<void> updateSetLog(SetLog log) async {
    final db = await database;
    await db.update(
      'set_logs',
      {
        'set_number': log.setNumber,
        'weight_kg': log.weightKg,
        'reps': log.reps,
        'note': log.note,
        'effort_type': log.effortType.dbValue,
      },
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  static Future<void> deleteSetLog(String id) async {
    final db = await database;
    await db.delete(
      'set_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Body Measurements
  static Future<void> insertBodyMeasurement(BodyMeasurement m) async {
    final db = await database;
    await db.insert(
      'body_measurements',
      _bodyMeasurementToRow(m),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<BodyMeasurement>> getBodyMeasurements() async {
    final db = await database;
    final result = await db.query('body_measurements', orderBy: 'date DESC');
    return result.map(_bodyMeasurementFromRow).toList();
  }

  static Future<void> updateBodyMeasurement(BodyMeasurement m) async {
    final db = await database;
    final row = Map<String, Object?>.from(_bodyMeasurementToRow(m))..remove('id');
    await db.update(
      'body_measurements',
      row,
      where: 'id = ?',
      whereArgs: [m.id],
    );
  }

  static Future<void> deleteBodyMeasurement(String id) async {
    final db = await database;
    await db.delete('body_measurements', where: 'id = ?', whereArgs: [id]);
  }

  static Map<String, Object?> _bodyMeasurementToRow(BodyMeasurement m) {
    return {
      'id': m.id,
      'date': m.date.toIso8601String(),
      'sex': m.sex.dbValue,
      'weight_kg': m.weightKg,
      'height_cm': m.heightCm,
      'biceps_right_cm': m.bicepsRightCm,
      'biceps_left_cm': m.bicepsLeftCm,
      'chest_cm': m.chestCm,
      'waist_cm': m.waistCm,
      'abdomen_cm': m.abdomenCm,
      'hip_cm': m.hipCm,
      'glutes_cm': m.glutesCm,
      'thigh_right_cm': m.thighRightCm,
      'thigh_left_cm': m.thighLeftCm,
      'calf_right_cm': m.calfRightCm,
      'calf_left_cm': m.calfLeftCm,
      'notes': m.notes,
    };
  }

  static BodyMeasurement _bodyMeasurementFromRow(Map<String, Object?> row) {
    double? parseNum(String key) {
      final v = row[key];
      if (v == null) return null;
      return (v as num).toDouble();
    }

    return BodyMeasurement(
      id: row['id'] as String,
      date: DateTime.parse(row['date'] as String),
      sex: bodySexFromDbValue(row['sex'] as String?),
      weightKg: parseNum('weight_kg'),
      heightCm: parseNum('height_cm'),
      bicepsRightCm: parseNum('biceps_right_cm'),
      bicepsLeftCm: parseNum('biceps_left_cm'),
      chestCm: parseNum('chest_cm'),
      waistCm: parseNum('waist_cm'),
      abdomenCm: parseNum('abdomen_cm'),
      hipCm: parseNum('hip_cm'),
      glutesCm: parseNum('glutes_cm'),
      thighRightCm: parseNum('thigh_right_cm'),
      thighLeftCm: parseNum('thigh_left_cm'),
      calfRightCm: parseNum('calf_right_cm'),
      calfLeftCm: parseNum('calf_left_cm'),
      notes: (row['notes'] as String?) ?? '',
    );
  }
}

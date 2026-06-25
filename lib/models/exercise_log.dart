import '../utils/exercise_key.dart';
import 'enums.dart';
import 'set_log.dart';

class ExerciseLog {
  final String id;
  final String exerciseName;
  final String exerciseKey;
  final int order;
  final String notes;
  final String repRange;
  final bool isCompleted;
  final String? workoutSessionId;
  final List<SetLog> sets;

  ExerciseLog({
    required this.id,
    required this.exerciseName,
    String? exerciseKey,
    required this.order,
    this.notes = '',
    this.repRange = '',
    this.isCompleted = false,
    this.workoutSessionId,
    List<SetLog>? sets,
  })  : exerciseKey = exerciseKey ?? ExerciseKeyUtil.make(exerciseName),
        sets = sets ?? <SetLog>[];

  String get effectiveExerciseKey {
    return exerciseKey.isEmpty ? ExerciseKeyUtil.make(exerciseName) : exerciseKey;
  }

  ExerciseStatus get status {
    if (isCompleted) {
      return ExerciseStatus.completed;
    }
    if (sets.isEmpty) {
      return ExerciseStatus.notStarted;
    }
    return ExerciseStatus.inProgress;
  }

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      id: json['id'] as String,
      exerciseName: json['exerciseName'] as String,
      exerciseKey: json['exerciseKey'] as String? ?? '',
      order: json['order'] as int,
      notes: json['notes'] as String? ?? '',
      repRange: json['repRange'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      workoutSessionId: json['workoutSessionId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseName': exerciseName,
      'exerciseKey': exerciseKey,
      'order': order,
      'notes': notes,
      'repRange': repRange,
      'isCompleted': isCompleted,
      'workoutSessionId': workoutSessionId,
    };
  }

  ExerciseLog copyWith({
    String? id,
    String? exerciseName,
    String? exerciseKey,
    int? order,
    String? notes,
    String? repRange,
    bool? isCompleted,
    String? workoutSessionId,
    List<SetLog>? sets,
  }) {
    return ExerciseLog(
      id: id ?? this.id,
      exerciseName: exerciseName ?? this.exerciseName,
      exerciseKey: exerciseKey ?? this.exerciseKey,
      order: order ?? this.order,
      notes: notes ?? this.notes,
      repRange: repRange ?? this.repRange,
      isCompleted: isCompleted ?? this.isCompleted,
      workoutSessionId: workoutSessionId ?? this.workoutSessionId,
      sets: sets ?? this.sets,
    );
  }

  @override
  String toString() =>
      'ExerciseLog(id: $id, exerciseName: $exerciseName, order: $order, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseLog &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

import 'exercise_log.dart';

class WorkoutSession {
  final String id;
  final String workoutTemplateId;
  final String workoutName;
  final DateTime date;
  final DateTime? finishedAt;
  final String notes;
  final bool isFinished;
  final List<ExerciseLog> exerciseLogs;

  WorkoutSession({
    required this.id,
    required this.workoutTemplateId,
    required this.workoutName,
    required this.date,
    this.finishedAt,
    this.notes = '',
    this.isFinished = false,
    List<ExerciseLog>? exerciseLogs,
  }) : exerciseLogs = exerciseLogs ?? <ExerciseLog>[];

  DateTime get startDate => date;

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as String,
      workoutTemplateId: json['workoutTemplateId'] as String? ?? '',
      workoutName: json['workoutName'] as String,
      date: DateTime.parse(json['date'] as String),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String)
          : null,
      notes: json['notes'] as String? ?? '',
      isFinished: json['isFinished'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutTemplateId': workoutTemplateId,
      'workoutName': workoutName,
      'date': date.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
      'notes': notes,
      'isFinished': isFinished,
    };
  }

  WorkoutSession copyWith({
    String? id,
    String? workoutTemplateId,
    String? workoutName,
    DateTime? date,
    DateTime? finishedAt,
    String? notes,
    bool? isFinished,
    List<ExerciseLog>? exerciseLogs,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      workoutTemplateId: workoutTemplateId ?? this.workoutTemplateId,
      workoutName: workoutName ?? this.workoutName,
      date: date ?? this.date,
      finishedAt: finishedAt ?? this.finishedAt,
      notes: notes ?? this.notes,
      isFinished: isFinished ?? this.isFinished,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
    );
  }

  @override
  String toString() =>
      'WorkoutSession(id: $id, workoutName: $workoutName, isFinished: $isFinished)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

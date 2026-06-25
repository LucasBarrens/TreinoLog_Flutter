import '../utils/exercise_key.dart';

class ExerciseTemplate {
  final String id;
  final String name;
  final String exerciseKey;
  final String workoutTemplateId;
  final String workoutName;
  final int order;
  final String defaultRepRange;
  final String defaultNotes;

  ExerciseTemplate({
    required this.id,
    required this.name,
    String? exerciseKey,
    required this.workoutTemplateId,
    required this.workoutName,
    required this.order,
    this.defaultRepRange = '',
    this.defaultNotes = '',
  }) : exerciseKey = exerciseKey ?? ExerciseKeyUtil.make(name);

  String get effectiveExerciseKey {
    return exerciseKey.isEmpty ? ExerciseKeyUtil.make(name) : exerciseKey;
  }

  factory ExerciseTemplate.fromJson(Map<String, dynamic> json) {
    return ExerciseTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      exerciseKey: json['exerciseKey'] as String? ?? '',
      workoutTemplateId: json['workoutTemplateId'] as String? ?? '',
      workoutName: json['workoutName'] as String,
      order: json['order'] as int,
      defaultRepRange: json['defaultRepRange'] as String? ?? '',
      defaultNotes: json['defaultNotes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exerciseKey': exerciseKey,
      'workoutTemplateId': workoutTemplateId,
      'workoutName': workoutName,
      'order': order,
      'defaultRepRange': defaultRepRange,
      'defaultNotes': defaultNotes,
    };
  }

  ExerciseTemplate copyWith({
    String? id,
    String? name,
    String? exerciseKey,
    String? workoutTemplateId,
    String? workoutName,
    int? order,
    String? defaultRepRange,
    String? defaultNotes,
  }) {
    return ExerciseTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      exerciseKey: exerciseKey ?? this.exerciseKey,
      workoutTemplateId: workoutTemplateId ?? this.workoutTemplateId,
      workoutName: workoutName ?? this.workoutName,
      order: order ?? this.order,
      defaultRepRange: defaultRepRange ?? this.defaultRepRange,
      defaultNotes: defaultNotes ?? this.defaultNotes,
    );
  }

  @override
  String toString() =>
      'ExerciseTemplate(id: $id, name: $name, workoutName: $workoutName, order: $order)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

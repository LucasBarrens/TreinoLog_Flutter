import 'enums.dart';

class SetLog {
  final String id;
  final int setNumber;
  final double weightKg;
  final int reps;
  final String note;
  final EffortType effortType;
  final String? exerciseLogId;

  SetLog({
    required this.id,
    required this.setNumber,
    this.weightKg = 0,
    this.reps = 0,
    this.note = '',
    this.effortType = EffortType.none,
    this.exerciseLogId,
  });

  factory SetLog.fromJson(Map<String, dynamic> json) {
    return SetLog(
      id: json['id'] as String,
      setNumber: json['setNumber'] as int,
      weightKg: (json['weightKg'] as num? ?? 0).toDouble(),
      reps: json['reps'] as int? ?? 0,
      note: json['note'] as String? ?? '',
      effortType: effortTypeFromDbValue(json['effortType'] as String? ?? 'none'),
      exerciseLogId: json['exerciseLogId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'setNumber': setNumber,
      'weightKg': weightKg,
      'reps': reps,
      'note': note,
      'effortType': effortType.dbValue,
      'exerciseLogId': exerciseLogId,
    };
  }

  SetLog copyWith({
    String? id,
    int? setNumber,
    double? weightKg,
    int? reps,
    String? note,
    EffortType? effortType,
    String? exerciseLogId,
  }) {
    return SetLog(
      id: id ?? this.id,
      setNumber: setNumber ?? this.setNumber,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      note: note ?? this.note,
      effortType: effortType ?? this.effortType,
      exerciseLogId: exerciseLogId ?? this.exerciseLogId,
    );
  }

  @override
  String toString() =>
      'SetLog(id: $id, setNumber: $setNumber, weightKg: $weightKg, reps: $reps)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetLog &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

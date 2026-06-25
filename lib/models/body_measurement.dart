enum BodySex { male, female, unspecified }

extension BodySexX on BodySex {
  String get dbValue {
    switch (this) {
      case BodySex.male:
        return 'male';
      case BodySex.female:
        return 'female';
      case BodySex.unspecified:
        return 'unspecified';
    }
  }

  String get label {
    switch (this) {
      case BodySex.male:
        return 'Homem';
      case BodySex.female:
        return 'Mulher';
      case BodySex.unspecified:
        return 'Não informado';
    }
  }
}

BodySex bodySexFromDbValue(String? value) {
  switch (value) {
    case 'male':
      return BodySex.male;
    case 'female':
      return BodySex.female;
    case 'unspecified':
    default:
      return BodySex.unspecified;
  }
}

class BodyMeasurement {
  final String id;
  final DateTime date;
  final BodySex sex;
  final double? weightKg;
  final double? heightCm;
  final double? bicepsRightCm;
  final double? bicepsLeftCm;
  final double? chestCm;
  final double? waistCm;
  final double? abdomenCm;
  final double? hipCm;
  final double? glutesCm;
  final double? thighRightCm;
  final double? thighLeftCm;
  final double? calfRightCm;
  final double? calfLeftCm;
  final String notes;

  BodyMeasurement({
    required this.id,
    required this.date,
    this.sex = BodySex.unspecified,
    this.weightKg,
    this.heightCm,
    this.bicepsRightCm,
    this.bicepsLeftCm,
    this.chestCm,
    this.waistCm,
    this.abdomenCm,
    this.hipCm,
    this.glutesCm,
    this.thighRightCm,
    this.thighLeftCm,
    this.calfRightCm,
    this.calfLeftCm,
    this.notes = '',
  });

  // Average of left/right biceps when both present, otherwise whichever is set.
  double? get averageBicepsCm => _averageOfPair(bicepsLeftCm, bicepsRightCm);

  // Prefer glutes when present; otherwise hip. The user-requested comparison
  // for "quadril/glúteos" treats them as a single bucket.
  double? get hipOrGlutesCm => glutesCm ?? hipCm;

  double? _averageOfPair(double? a, double? b) {
    if (a != null && b != null) return (a + b) / 2;
    return a ?? b;
  }

  BodyMeasurement copyWith({
    String? id,
    DateTime? date,
    BodySex? sex,
    double? weightKg,
    double? heightCm,
    double? bicepsRightCm,
    double? bicepsLeftCm,
    double? chestCm,
    double? waistCm,
    double? abdomenCm,
    double? hipCm,
    double? glutesCm,
    double? thighRightCm,
    double? thighLeftCm,
    double? calfRightCm,
    double? calfLeftCm,
    String? notes,
    // copyWith intentionally does not support clearing a nullable to null —
    // callers building a new measurement just pass the new value (or omit).
  }) {
    return BodyMeasurement(
      id: id ?? this.id,
      date: date ?? this.date,
      sex: sex ?? this.sex,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      bicepsRightCm: bicepsRightCm ?? this.bicepsRightCm,
      bicepsLeftCm: bicepsLeftCm ?? this.bicepsLeftCm,
      chestCm: chestCm ?? this.chestCm,
      waistCm: waistCm ?? this.waistCm,
      abdomenCm: abdomenCm ?? this.abdomenCm,
      hipCm: hipCm ?? this.hipCm,
      glutesCm: glutesCm ?? this.glutesCm,
      thighRightCm: thighRightCm ?? this.thighRightCm,
      thighLeftCm: thighLeftCm ?? this.thighLeftCm,
      calfRightCm: calfRightCm ?? this.calfRightCm,
      calfLeftCm: calfLeftCm ?? this.calfLeftCm,
      notes: notes ?? this.notes,
    );
  }

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    double? parseNum(String key) {
      final v = json[key];
      if (v == null) return null;
      return (v as num).toDouble();
    }

    return BodyMeasurement(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      sex: bodySexFromDbValue(json['sex'] as String?),
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
      notes: (json['notes'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'sex': sex.dbValue,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'biceps_right_cm': bicepsRightCm,
      'biceps_left_cm': bicepsLeftCm,
      'chest_cm': chestCm,
      'waist_cm': waistCm,
      'abdomen_cm': abdomenCm,
      'hip_cm': hipCm,
      'glutes_cm': glutesCm,
      'thigh_right_cm': thighRightCm,
      'thigh_left_cm': thighLeftCm,
      'calf_right_cm': calfRightCm,
      'calf_left_cm': calfLeftCm,
      'notes': notes,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyMeasurement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

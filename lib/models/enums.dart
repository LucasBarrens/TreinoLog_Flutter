enum EffortType {
  none,
  warmUp,
  technicalFailure,
  totalFailure,
  rir,
  cluster,
  backoff,
}

extension EffortTypeExt on EffortType {
  String get title {
    switch (this) {
      case EffortType.none:
        return 'Nenhum';
      case EffortType.warmUp:
        return 'Warm-up';
      case EffortType.technicalFailure:
        return 'Falha técnica';
      case EffortType.totalFailure:
        return 'Falha total';
      case EffortType.rir:
        return 'RIR';
      case EffortType.cluster:
        return 'Cluster';
      case EffortType.backoff:
        return 'Backoff';
    }
  }

  String get dbValue {
    return name;
  }
}

EffortType effortTypeFromDbValue(String value) {
  return EffortType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => EffortType.none,
  );
}

enum ExerciseStatus {
  notStarted,
  inProgress,
  completed,
}

extension ExerciseStatusExt on ExerciseStatus {
  String get title {
    switch (this) {
      case ExerciseStatus.notStarted:
        return 'Não iniciado';
      case ExerciseStatus.inProgress:
        return 'Em andamento';
      case ExerciseStatus.completed:
        return 'Concluído';
    }
  }
}

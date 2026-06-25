import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestTimerState {
  final DateTime? endDate;
  final bool isRunning;
  final int remainingSeconds;
  final int lastPresetSeconds;

  const RestTimerState({
    required this.endDate,
    required this.isRunning,
    required this.remainingSeconds,
    required this.lastPresetSeconds,
  });

  factory RestTimerState.empty() {
    return const RestTimerState(
      endDate: null,
      isRunning: false,
      remainingSeconds: 0,
      lastPresetSeconds: 90,
    );
  }

  RestTimerState copyWith({
    DateTime? endDate,
    bool? isRunning,
    int? remainingSeconds,
    int? lastPresetSeconds,
  }) {
    return RestTimerState(
      endDate: endDate ?? this.endDate,
      isRunning: isRunning ?? this.isRunning,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      lastPresetSeconds: lastPresetSeconds ?? this.lastPresetSeconds,
    );
  }
}

final restTimerProvider =
    StateProvider.family<RestTimerState, String>((ref, exerciseLogId) {
  return RestTimerState.empty();
});

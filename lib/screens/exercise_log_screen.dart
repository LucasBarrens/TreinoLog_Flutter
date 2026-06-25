import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/index.dart';
import '../theme/app_theme.dart';
import '../utils/index.dart';
import '../providers/index.dart';
import 'exercise_progress_screen.dart';
import 'exercise_log_components.dart';

class ExerciseLogScreen extends ConsumerStatefulWidget {
  final ExerciseLog exerciseLog;

  const ExerciseLogScreen({required this.exerciseLog, Key? key}) : super(key: key);

  @override
  ConsumerState<ExerciseLogScreen> createState() => _ExerciseLogScreenState();
}

class _ExerciseLogScreenState extends ConsumerState<ExerciseLogScreen>
    with WidgetsBindingObserver {
  late ExerciseLog _exerciseLog;
  late final TextEditingController _notesController;
  Timer? _restTimer;

  int _remainingRestSeconds = 0;
  bool _isRestTimerRunning = false;
  int _lastRestPreset = 90;
  DateTime? _endDate;

  static const List<int> _restPresets = [60, 90, 120, 180];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _exerciseLog = widget.exerciseLog;
    _notesController = TextEditingController(text: widget.exerciseLog.notes);
    _restoreTimerState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recalculateFromWallClock();
    }
  }

  void _recalculateFromWallClock() {
    if (_endDate == null || !_isRestTimerRunning) return;
    final remaining = _endDate!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _restTimer?.cancel();
      setState(() {
        _remainingRestSeconds = 0;
        _isRestTimerRunning = false;
      });
      _endDate = null;
      _clearTimerState();
      _showTimerCompleteAlert();
    } else {
      setState(() {
        _remainingRestSeconds = remaining;
      });
    }
  }

  void _restoreTimerState() {
    final storedState = ref.read(restTimerProvider(_exerciseLog.id));
    _lastRestPreset = storedState.lastPresetSeconds;
    _isRestTimerRunning = storedState.isRunning;
    _endDate = storedState.endDate;

    if (storedState.isRunning) {
      final restoredRemaining = _endDate != null
          ? _endDate!.difference(DateTime.now()).inSeconds
          : storedState.remainingSeconds;
      if (restoredRemaining > 0) {
        _remainingRestSeconds = restoredRemaining;
        _startTicker();
      } else {
        _remainingRestSeconds = 0;
        _isRestTimerRunning = false;
        _endDate = null;
        _clearTimerState();
      }
    } else {
      _remainingRestSeconds = storedState.remainingSeconds;
    }
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    _endDate = DateTime.now().add(Duration(seconds: seconds));
    setState(() {
      _lastRestPreset = seconds;
      _remainingRestSeconds = seconds;
      _isRestTimerRunning = true;
    });
    ref.read(restTimerProvider(_exerciseLog.id).notifier).state = RestTimerState(
      endDate: _endDate,
      isRunning: true,
      remainingSeconds: seconds,
      lastPresetSeconds: seconds,
    );
    _startTicker();
    HapticFeedback.lightImpact();
  }

  void _onRestTick(Timer timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }
    if (_endDate == null) {
      timer.cancel();
      return;
    }
    final remaining = _endDate!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      timer.cancel();
      setState(() {
        _remainingRestSeconds = 0;
        _isRestTimerRunning = false;
      });
      _endDate = null;
      _clearTimerState();
      _showTimerCompleteAlert();
    } else {
      setState(() {
        _remainingRestSeconds = remaining;
      });
    }
  }

  void _showTimerCompleteAlert() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descanso completo!'),
        content: const Text('Você completou o tempo de descanso.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _toggleRestTimer() {
    if (_remainingRestSeconds <= 0) return;
    setState(() => _isRestTimerRunning = !_isRestTimerRunning);
    if (_isRestTimerRunning) {
      _endDate = DateTime.now().add(Duration(seconds: _remainingRestSeconds));
      ref.read(restTimerProvider(_exerciseLog.id).notifier).state = RestTimerState(
        endDate: _endDate,
        isRunning: true,
        remainingSeconds: _remainingRestSeconds,
        lastPresetSeconds: _lastRestPreset,
      );
      _startTicker();
    } else {
      _restTimer?.cancel();
      ref.read(restTimerProvider(_exerciseLog.id).notifier).state = RestTimerState(
        endDate: DateTime.now().add(Duration(seconds: _remainingRestSeconds)),
        isRunning: false,
        remainingSeconds: _remainingRestSeconds,
        lastPresetSeconds: _lastRestPreset,
      );
    }
  }

  void _resetRestTimer() {
    _restTimer?.cancel();
    _endDate = null;
    setState(() {
      _remainingRestSeconds = 0;
      _isRestTimerRunning = false;
    });
    _clearTimerState();
  }

  void _startTicker() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), _onRestTick);
  }

  void _clearTimerState() {
    ref.read(restTimerProvider(_exerciseLog.id).notifier).state = RestTimerState.empty();
  }

  Future<void> _addSet(List<SetLog> currentSets) async {
    final suggestedWeight = currentSets.isNotEmpty ? currentSets.last.weightKg : 0.0;
    final newSet = SetLog(
      id: const Uuid().v4(),
      setNumber: currentSets.length + 1,
      weightKg: suggestedWeight,
      reps: 0,
      exerciseLogId: _exerciseLog.id,
    );
    await ref.read(workoutActionsProvider).createSetLog(newSet);
    HapticFeedback.lightImpact();
    _startRestTimer(_lastRestPreset);
    ref.invalidate(setLogsProvider(_exerciseLog.id));
  }

  Future<void> _duplicateLastSet(List<SetLog> currentSets) async {
    if (currentSets.isEmpty) return;
    final lastSet = currentSets.last;
    final newSet = SetLog(
      id: const Uuid().v4(),
      setNumber: lastSet.setNumber + 1,
      weightKg: lastSet.weightKg,
      reps: lastSet.reps,
      note: lastSet.note,
      effortType: lastSet.effortType,
      exerciseLogId: _exerciseLog.id,
    );
    await ref.read(workoutActionsProvider).createSetLog(newSet);
    HapticFeedback.lightImpact();
    _startRestTimer(_lastRestPreset);
    ref.invalidate(setLogsProvider(_exerciseLog.id));
  }

  Future<void> _copyFromLastSession() async {
    final history = await ref
        .read(exerciseHistoryProvider(_exerciseLog.effectiveExerciseKey).future);
    // Skip entries from the current session if any leaked in.
    final previous = history.firstWhere(
      (entry) => entry.session.id != _exerciseLog.workoutSessionId,
      orElse: () => history.isNotEmpty
          ? history.first
          : ExerciseHistoryEntry(
              session: WorkoutSession(
                id: '',
                workoutTemplateId: '',
                workoutName: '',
                date: DateTime.now(),
              ),
              exerciseLog: _exerciseLog,
            ),
    );
    if (previous.sets.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sem treino anterior para copiar.')),
      );
      return;
    }

    final actions = ref.read(workoutActionsProvider);
    for (var i = 0; i < previous.sets.length; i++) {
      final src = previous.sets[i];
      await actions.createSetLog(SetLog(
        id: const Uuid().v4(),
        setNumber: i + 1,
        weightKg: src.weightKg,
        reps: src.reps,
        note: src.note,
        effortType: src.effortType,
        exerciseLogId: _exerciseLog.id,
      ));
    }
    HapticFeedback.lightImpact();
    ref.invalidate(setLogsProvider(_exerciseLog.id));
  }

  Future<void> _updateSet(SetLog set) async {
    await ref.read(workoutActionsProvider).updateSetLog(set);
    ref.invalidate(setLogsProvider(_exerciseLog.id));
  }

  Future<void> _deleteSet(SetLog set, List<SetLog> currentSets) async {
    final actions = ref.read(workoutActionsProvider);
    await actions.deleteSetLog(set.id);
    final remaining = currentSets.where((s) => s.id != set.id).toList();
    for (var i = 0; i < remaining.length; i++) {
      if (remaining[i].setNumber != i + 1) {
        await actions.updateSetLog(remaining[i].copyWith(setNumber: i + 1));
      }
    }
    ref.invalidate(setLogsProvider(_exerciseLog.id));
  }

  Future<void> _finishExercise() async {
    _exerciseLog = _exerciseLog.copyWith(isCompleted: true);
    await ref.read(workoutActionsProvider).updateExerciseLog(_exerciseLog);
    HapticFeedback.lightImpact();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final setsAsync = ref.watch(setLogsProvider(_exerciseLog.id));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_exerciseLog.exerciseName),
            if (_exerciseLog.repRange.isNotEmpty)
              Text(
                'Meta: ${_exerciseLog.repRange} reps',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ),
      body: setsAsync.when(
        data: (sets) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer(builder: (context, ref, _) {
                final historyAsync = ref.watch(
                  exerciseHistoryProvider(_exerciseLog.effectiveExerciseKey),
                );
                return historyAsync.when(
                  data: (history) {
                    SetLog? lastWorkoutBestSet;
                    for (final entry in history) {
                      if (entry.session.id == _exerciseLog.workoutSessionId) continue;
                      if (entry.exerciseLog.sets.isNotEmpty) {
                        lastWorkoutBestSet = VolumeCalculator.findBestSet(
                          entry.exerciseLog.sets,
                        );
                        break;
                      }
                    }
                    return ProgressionCard(
                      sets: sets,
                      lastWorkoutBestSet: lastWorkoutBestSet,
                      onViewHistory: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExerciseProgressScreen(
                            exerciseName: _exerciseLog.exerciseName,
                            exerciseKey: _exerciseLog.effectiveExerciseKey,
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => ProgressionCard(
                    sets: sets,
                    onViewHistory: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExerciseProgressScreen(
                          exerciseName: _exerciseLog.exerciseName,
                          exerciseKey: _exerciseLog.effectiveExerciseKey,
                        ),
                      ),
                    ),
                  ),
                  error: (_, __) => ProgressionCard(
                    sets: sets,
                    onViewHistory: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExerciseProgressScreen(
                          exerciseName: _exerciseLog.exerciseName,
                          exerciseKey: _exerciseLog.effectiveExerciseKey,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              RestTimerCard(
                remainingRestSeconds: _remainingRestSeconds,
                isTimerRunning: _isRestTimerRunning,
                lastRestPreset: _lastRestPreset,
                restPresets: _restPresets,
                onToggleTimer: _toggleRestTimer,
                onResetTimer: _resetRestTimer,
                onPresetSelected: _startRestTimer,
              ),
              const SizedBox(height: 24),
              Consumer(builder: (context, ref, _) {
                final historicBest = ref
                    .watch(historicBestOneRmProvider(HistoricBestArgs(
                      _exerciseLog.effectiveExerciseKey,
                      excludeSessionId: _exerciseLog.workoutSessionId,
                    )))
                    .maybeWhen(data: (v) => v, orElse: () => 0.0);
                return _buildSetsList(sets, historicBest);
              }),
              const SizedBox(height: 16),
              ExerciseNotesField(
                controller: _notesController,
                onChanged: _onNotesChanged,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _finishExercise,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: const Text('Finalizar exercício'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  Widget _buildSetsList(List<SetLog> sets, double historicBestOneRm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Séries',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
            ),
            if (sets.isNotEmpty)
              Text(
                '${sets.length} registrada${sets.length > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (sets.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 32,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Nenhuma série ainda',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => _addSet(sets),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar primeira série'),
                  ),
                  Consumer(builder: (context, ref, _) {
                    final hasHistory = ref
                        .watch(exerciseHistoryProvider(_exerciseLog.effectiveExerciseKey))
                        .maybeWhen(
                          data: (entries) => entries.any((e) =>
                              e.session.id != _exerciseLog.workoutSessionId &&
                              e.sets.isNotEmpty),
                          orElse: () => false,
                        );
                    if (!hasHistory) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: _copyFromLastSession,
                        icon: const Icon(Icons.replay_rounded, size: 16),
                        label: const Text('Copiar do último treino'),
                      ),
                    );
                  }),
                ],
              ),
            ),
          )
        else ...[
          ...sets.map(
            (set) => SetLogCard(
              key: ValueKey(set.id),
              set: set,
              historicBestOneRm: historicBestOneRm,
              onUpdate: _updateSet,
              onDelete: (s) => _deleteSet(s, sets),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _addSet(sets),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Série'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _duplicateLastSet(sets),
                  icon: const Icon(Icons.content_copy_rounded, size: 16),
                  label: const Text('Duplicar'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _onNotesChanged(String value) {
    _exerciseLog = _exerciseLog.copyWith(notes: value);
    unawaited(ref.read(workoutActionsProvider).updateExerciseLog(_exerciseLog));
  }
}

enum _SetMenuAction { delete }

// ── SetLogCard com Steppers ───────────────────────────────────────────────────

class SetLogCard extends StatefulWidget {
  final SetLog set;
  final Function(SetLog) onUpdate;
  final Function(SetLog) onDelete;
  // Best historic estimated 1RM for this exercise (excludes the current
  // session). If this set beats it, a PR badge shows next to "Série N".
  final double historicBestOneRm;

  const SetLogCard({
    required this.set,
    required this.onUpdate,
    required this.onDelete,
    this.historicBestOneRm = 0,
    Key? key,
  }) : super(key: key);

  @override
  State<SetLogCard> createState() => _SetLogCardState();
}

class _SetLogCardState extends State<SetLogCard> {
  late double _weight;
  late int _reps;
  late EffortType _effortType;
  late TextEditingController _noteController;
  bool _showNote = false;

  @override
  void initState() {
    super.initState();
    _weight = widget.set.weightKg;
    _reps = widget.set.reps;
    _effortType = widget.set.effortType;
    _noteController = TextEditingController(text: widget.set.note);
    _showNote = widget.set.note.isNotEmpty;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final updated = widget.set.copyWith(
      weightKg: _weight,
      reps: _reps,
      note: _noteController.text,
      effortType: _effortType,
    );
    widget.onUpdate(updated);
  }

  void _adjustWeight(double delta) {
    setState(() {
      _weight = (_weight + delta).clamp(0.0, 9999.0);
      // Round to nearest 0.5
      _weight = ((_weight * 2).round() / 2);
    });
    _save();
  }

  void _adjustReps(int delta) {
    setState(() {
      _reps = (_reps + delta).clamp(0, 999);
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Série ${widget.set.setNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                ),
                if (PrCalculator.isPr(
                  widget.set.copyWith(weightKg: _weight, reps: _reps),
                  widget.historicBestOneRm,
                )) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events_rounded,
                            size: 13, color: AppColors.warning),
                        const SizedBox(width: 3),
                        Text(
                          'PR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                // Effort type (compact)
                if (_effortType != EffortType.none)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warningMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _effortType.title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                PopupMenuButton<_SetMenuAction>(
                  icon: Icon(Icons.more_vert_rounded, size: 18, color: colors.onSurfaceVariant),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: _SetMenuAction.delete, child: Text('Apagar')),
                  ],
                  onSelected: (value) {
                    if (value == _SetMenuAction.delete) widget.onDelete(widget.set);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Steppers row
            Row(
              children: [
                Expanded(
                  child: _StepperField(
                    label: 'Carga (kg)',
                    displayValue: FormattingUtil.formatWeight(_weight),
                    onDecrement: () => _adjustWeight(-2.5),
                    onDecrementFast: () => _adjustWeight(-5),
                    onIncrement: () => _adjustWeight(2.5),
                    onIncrementFast: () => _adjustWeight(5),
                    onTap: () => _showWeightDialog(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StepperField(
                    label: 'Repetições',
                    displayValue: '$_reps',
                    onDecrement: _reps > 0 ? () => _adjustReps(-1) : null,
                    onDecrementFast: _reps >= 5 ? () => _adjustReps(-5) : null,
                    onIncrement: () => _adjustReps(1),
                    onIncrementFast: () => _adjustReps(5),
                    onTap: () => _showRepsDialog(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Effort + note row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<EffortType>(
                    value: _effortType,
                    decoration: InputDecoration(
                      labelText: 'Esforço',
                      labelStyle: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                    ),
                    style: TextStyle(fontSize: 13, color: colors.onSurface),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _effortType = value);
                        _save();
                      }
                    },
                    items: EffortType.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.title)))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => setState(() => _showNote = !_showNote),
                  icon: Icon(
                    _showNote ? Icons.notes_rounded : Icons.add_comment_outlined,
                    size: 20,
                    color: _showNote ? colors.primary : colors.onSurfaceVariant,
                  ),
                  tooltip: _showNote ? 'Ocultar nota' : 'Adicionar nota',
                ),
              ],
            ),
            if (_showNote) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'Observação sobre esta série'),
                onChanged: (_) => _save(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showWeightDialog() async {
    final controller = TextEditingController(
      text: _weight == 0 ? '' : FormattingUtil.formatWeight(_weight),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Carga (kg)'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ex: 80'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final val = FormattingUtil.parseWeight(controller.text);
              Navigator.pop(ctx, val);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _weight = result);
      _save();
    }
    controller.dispose();
  }

  Future<void> _showRepsDialog() async {
    final controller = TextEditingController(text: _reps == 0 ? '' : '$_reps');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Repetições'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ex: 10'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text) ?? _reps;
              Navigator.pop(ctx, val);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _reps = result);
      _save();
    }
    controller.dispose();
  }
}

// ── Stepper Field ─────────────────────────────────────────────────────────────

class _StepperField extends StatelessWidget {
  final String label;
  final String displayValue;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onTap;
  final VoidCallback? onDecrementFast;
  final VoidCallback? onIncrementFast;

  const _StepperField({
    required this.label,
    required this.displayValue,
    required this.onDecrement,
    required this.onIncrement,
    required this.onTap,
    this.onDecrementFast,
    this.onIncrementFast,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _StepBtn(
                icon: Icons.remove,
                onTap: onDecrement,
                onLongPress: onDecrementFast,
                isLeft: true,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Center(
                    child: Text(
                      displayValue,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                    ),
                  ),
                ),
              ),
              _StepBtn(
                icon: Icons.add,
                onTap: onIncrement,
                onLongPress: onIncrementFast,
                isLeft: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isLeft;

  const _StepBtn({required this.icon, required this.onTap, this.onLongPress, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    return SizedBox(
      width: 52,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(12) : Radius.zero,
            right: isLeft ? Radius.zero : const Radius.circular(12),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: enabled ? colors.primary : colors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

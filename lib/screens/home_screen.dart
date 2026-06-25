import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/index.dart';
import '../services/backup_service.dart';
import '../theme/app_theme.dart';
import '../utils/index.dart';
import '../providers/index.dart';
import 'saved_workouts_screen.dart';
import 'pre_workout_screen.dart';
import 'workout_execution_screen.dart';
import 'body_measurements_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(workoutTemplatesProvider);
    final sessionsAsync = ref.watch(workoutSessionsWithLogsProvider);
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      body: workoutsAsync.when(
        data: (workouts) => sessionsAsync.when(
          data: (sessions) {
            final inProgressSession = sessions.firstWhereOrNull(
              (s) => VolumeCalculator.isRecoverableInProgress(s),
            );
            final registeredSessions = sessions
                .where((s) => s.isFinished && VolumeCalculator.hasRegisteredSets(s))
                .toList();

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  title: const Text('GymLog'),
                  actions: [
                    PopupMenuButton<_BackupMenuAction>(
                      icon: const Icon(Icons.backup_outlined),
                      tooltip: 'Backup',
                      onSelected: (action) {
                        switch (action) {
                          case _BackupMenuAction.export:
                            _exportBackup(context, ref);
                            return;
                          case _BackupMenuAction.import:
                            _importBackup(context, ref);
                            return;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _BackupMenuAction.export,
                          child: Text('Exportar backup'),
                        ),
                        PopupMenuItem(
                          value: _BackupMenuAction.import,
                          child: Text('Importar backup'),
                        ),
                      ],
                    ),
                    IconButton(
                      tooltip: isDarkMode ? 'Modo claro' : 'Modo escuro',
                      icon: Icon(
                        isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      ),
                      onPressed: () {
                        ref.read(themeProvider.notifier).state =
                            isDarkMode ? ThemeMode.light : ThemeMode.dark;
                      },
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: _GreetingHeader(
                      sessionCount: registeredSessions.length,
                      onHistoryTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SavedWorkoutsScreen()),
                      ),
                    ),
                  ),
                ),
                if (inProgressSession != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: _InProgressCard(
                        session: inProgressSession,
                        onWorkoutChanged: () {
                          ref.invalidate(workoutSessionsWithLogsProvider);
                        },
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _MeasurementsEntryCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BodyMeasurementsScreen(),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _WorkoutsSection(workouts: workouts),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Erro: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await BackupService.exportAndShareBackup();
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Falha ao exportar: $error')));
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar backup'),
        content: const Text(
          'Isso substituirá todos os dados atuais pelo backup selecionado. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Importar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      await BackupService.importJsonBackup(file);

      if (!context.mounted) return;
      ref.invalidate(workoutTemplatesProvider);
      ref.invalidate(workoutSessionsWithLogsProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Backup importado com sucesso!')),
      );
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Falha ao importar: $error')));
    }
  }
}

enum _BackupMenuAction { export, import }

extension on List<WorkoutSession> {
  WorkoutSession? firstWhereOrNull(bool Function(WorkoutSession) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}

// ── Greeting ──────────────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  final int sessionCount;
  final VoidCallback onHistoryTap;

  const _GreetingHeader({required this.sessionCount, required this.onHistoryTap});

  static const _motivationalMorning = [
    'O cafezinho pode esperar. O treino não.',
    'Você dormiu. Os músculos também. Hora de acordar os dois.',
    'Essa semana não vai se treinar sozinha.',
    'Seu futuro eu já está com inveja de você agora.',
    'A dor de hoje é a pose de amanhã.',
    'O universo não recompensa quem fica na cama.',
    'Sócrates dizia: conhece-te a ti mesmo. Mas ele não tinha visto uma barra.',
  ];

  static const _motivationalAfternoon = [
    'O almoço pesou? Usa no treino.',
    'Meio do dia, meio do caminho. Vai lá.',
    'Seu colega foi tomar café. Você vai malhar.',
    'Ninguém reclama de treinar à tarde no espelho.',
    'O metabolismo agradece. Literalmente.',
    'Nietzsche disse: o que não te mata te fortalece. Ele estava falando de agachamento.',
    'A gravidade puxa tudo pra baixo. Você levanta assim mesmo.',
  ];

  static const _motivationalEvening = [
    'O dia foi pesado? Vai malhar e fica mais pesado ainda.',
    'A série que você não fez hoje vai aparecer no espelho amanhã.',
    'Treino noturno: eficiente, silencioso, implacável.',
    'Não tem desculpa. A academia não fecha antes de você.',
    'Quem treina de noite acorda campeão.',
    'O corpo é temporário. A consistência é eterna.',
    'Marcus Aurelius treinava todo dia. Não existe prova disso, mas faz sentido.',
  ];

  static const _weekendLines = [
    'Final de semana não é descanso, é vantagem.',
    'Enquanto todo mundo faz churrasco, você faz séries.',
    'Sábado ou domingo — os músculos não têm calendário, não curtem Stories e não ligam pra feriado.',
    'Descansar é filosófico. Mas só depois de treinar.',
    'O universo é indiferente ao seu dia de folga. Os músculos também.',
  ];

  static const _philosophical = [
    'Heráclito disse que tudo flui. Inclusive o seu peso na barra.',
    'A cada rep, você derrota uma versão menor de si mesmo.',
    'O espelho não mente. Mas ele também não conta as séries que você pulou.',
    'Ser ou não ser forte — essa não é a questão. A questão é quantas séries.',
    'A filosofia budista fala de desapego. Mas não do peso morto.',
    'Todo grande filósofo tinha uma coisa em comum: nenhum deles pulava treino.',
    'O tempo é relativo. Exceto o descanso entre séries — esse passa lento de verdade.',
  ];

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String _weekday() {
    const days = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    return days[DateTime.now().weekday - 1];
  }

  String _motivational() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final hour = now.hour;

    // A cada 3 exibições, usa uma frase filosófica independente do horário
    final usePhilosophical = (now.day + now.hour) % 3 == 0;
    if (usePhilosophical) {
      final index = (now.day * 7 + now.hour) % _philosophical.length;
      return _philosophical[index];
    }

    List<String> pool;
    if (weekday >= 6) {
      pool = _weekendLines;
    } else if (hour < 12) {
      pool = _motivationalMorning;
    } else if (hour < 18) {
      pool = _motivationalAfternoon;
    } else {
      pool = _motivationalEvening;
    }

    final index = (now.day + now.hour) % pool.length;
    return pool[index];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                _weekday(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                _motivational(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
        ),
        if (sessionCount > 0)
          InkWell(
            onTap: onHistoryTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_rounded, size: 16, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '$sessionCount treinos',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── In Progress ───────────────────────────────────────────────────────────────

class _InProgressCard extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback onWorkoutChanged;

  const _InProgressCard({required this.session, required this.onWorkoutChanged});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutExecutionScreen(session: session),
            ),
          );
          if (result == true) onWorkoutChanged();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Em andamento',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      session.workoutName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      VolumeCalculator.formatDuration(session.startDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Measurements Entry ────────────────────────────────────────────────────────

class _MeasurementsEntryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _MeasurementsEntryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.straighten_rounded,
                    color: colors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medidas',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Acompanhe seu peso e medidas corporais',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Workouts Section ──────────────────────────────────────────────────────────

class _WorkoutsSection extends ConsumerWidget {
  final List<WorkoutTemplate> workouts;

  const _WorkoutsSection({required this.workouts});

  Future<void> _createWorkout(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo treino'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nome do treino (ex: Upper A)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final newWorkout = WorkoutTemplate(
        id: const Uuid().v4(),
        name: result,
        order: workouts.length,
      );
      await ref.read(workoutActionsProvider).createWorkoutTemplate(newWorkout);
      ref.invalidate(workoutTemplatesProvider);
    }
    controller.dispose();
  }

  Future<void> _deleteWorkout(BuildContext context, WidgetRef ref, WorkoutTemplate workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar treino?'),
        content: const Text(
          'Isso remove apenas o template e seus exercícios. '
          'O histórico não será apagado.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final exercises = await ref.read(exerciseTemplatesProvider(workout.name).future);
    final actions = ref.read(workoutActionsProvider);
    for (final exercise in exercises) {
      await actions.deleteExerciseTemplate(exercise.id);
    }
    await actions.deleteWorkoutTemplate(workout.id);
    ref.invalidate(workoutTemplatesProvider);
  }

  Future<void> _editWorkout(BuildContext context, WidgetRef ref, WorkoutTemplate workout) async {
    final controller = TextEditingController(text: workout.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar treino'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nome do treino'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final updatedWorkout = workout.copyWith(name: result);
      await ref.read(workoutActionsProvider).updateWorkoutTemplate(updatedWorkout);
      ref.invalidate(workoutTemplatesProvider);
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Meus treinos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _createWorkout(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Novo'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (workouts.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.fitness_center_rounded, color: colors.primary, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text('Sem treinos ainda', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'Crie o primeiro treino para montar sua divisão.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return _ExerciseCountBuilder(
                workoutName: workout.name,
                builder: (exerciseCount) => _WorkoutCard(
                  workout: workout,
                  exerciseCount: exerciseCount,
                  onTap: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => PreWorkoutScreen(workout: workout)),
                    );
                    if (result == true) {
                      ref.invalidate(workoutSessionsWithLogsProvider);
                    }
                  },
                  onEdit: () => _editWorkout(context, ref, workout),
                  onDelete: () => _deleteWorkout(context, ref, workout),
                ),
              );
            },
          ),
      ],
    );
  }
}

// Cores de avatar por posição
const _avatarColors = [
  Color(0xFF1741D4),
  Color(0xFF0E7F6A),
  Color(0xFF7C3AED),
  Color(0xFFB45309),
  Color(0xFF0369A1),
  Color(0xFF9D174D),
];

class _WorkoutCard extends StatelessWidget {
  final WorkoutTemplate workout;
  final int exerciseCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WorkoutCard({
    required this.workout,
    required this.exerciseCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final avatarColor = _avatarColors[workout.name.length % _avatarColors.length];
    final initials = workout.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: avatarColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: avatarColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exerciseCount == 0
                          ? 'Nenhum exercício'
                          : '$exerciseCount exercício${exerciseCount > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_WorkoutMenuAction>(
                icon: Icon(Icons.more_vert_rounded, color: colors.onSurfaceVariant, size: 20),
                onSelected: (value) {
                  switch (value) {
                    case _WorkoutMenuAction.edit:
                      onEdit();
                      return;
                    case _WorkoutMenuAction.delete:
                      onDelete();
                      return;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: _WorkoutMenuAction.edit, child: Text('Editar')),
                  PopupMenuItem(value: _WorkoutMenuAction.delete, child: Text('Apagar')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _WorkoutMenuAction { edit, delete }

class _ExerciseCountBuilder extends ConsumerWidget {
  final String workoutName;
  final Widget Function(int) builder;

  const _ExerciseCountBuilder({required this.workoutName, required this.builder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exerciseTemplatesProvider(workoutName));
    return exercisesAsync.when(
      data: (exercises) => builder(exercises.length),
      loading: () => builder(0),
      error: (_, __) => builder(0),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/index.dart';
import 'screens/index.dart';
import 'providers/index.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SeedDataService.ensureInitialData();
  // Best-effort daily snapshot kept in app docs. Runs in the background; never
  // blocks startup.
  BackupService.runAutoDailyBackupIfNeeded();
  runApp(const ProviderScope(child: GymLogApp()));
}

class GymLogApp extends ConsumerWidget {
  const GymLogApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'GymLog',
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}

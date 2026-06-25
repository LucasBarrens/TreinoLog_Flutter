import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/database_service.dart';

final bodyMeasurementsProvider =
    FutureProvider<List<BodyMeasurement>>((ref) async {
  return DatabaseService.getBodyMeasurements();
});

final bodyMeasurementActionsProvider =
    Provider((ref) => const BodyMeasurementActions());

class BodyMeasurementActions {
  const BodyMeasurementActions();

  Future<void> create(BodyMeasurement m) =>
      DatabaseService.insertBodyMeasurement(m);

  Future<void> update(BodyMeasurement m) =>
      DatabaseService.updateBodyMeasurement(m);

  Future<void> delete(String id) =>
      DatabaseService.deleteBodyMeasurement(id);
}

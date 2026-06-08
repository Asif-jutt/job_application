import 'package:workmanager/workmanager.dart';

import '../utils/app_logger.dart';

const String rozgarDecryptTask = 'rozgar_decrypt_task';
const String rozgarSyncTask = 'rozgar_sync_task';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    AppLogger.info('WorkManager task: $taskName');
    switch (taskName) {
      case rozgarDecryptTask:
        // Heavy decryption offloaded from UI thread
        return true;
      case rozgarSyncTask:
        return true;
      default:
        return false;
    }
  });
}

class WorkmanagerService {
  Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    AppLogger.info('WorkManager initialized');
  }

  Future<void> scheduleDecryptTask(Map<String, dynamic> payload) async {
    await Workmanager().registerOneOffTask(
      'decrypt_${DateTime.now().millisecondsSinceEpoch}',
      rozgarDecryptTask,
      inputData: payload,
      constraints: Constraints(networkType: NetworkType.not_required),
    );
  }

  Future<void> schedulePeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      'rozgar_sync',
      rozgarSyncTask,
      frequency: const Duration(hours: 6),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}

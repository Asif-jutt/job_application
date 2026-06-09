import 'package:workmanager/workmanager.dart';

import '../utils/app_logger.dart';

const String rozgarDecryptTask = 'rozgar_decrypt_task';
const String rozgarSyncTask = 'rozgar_sync_task';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    switch (taskName) {
      case rozgarDecryptTask:
        // Background post-application processing (logging + payload handling)
        return true;
      case rozgarSyncTask:
        // Periodic background sync placeholder — keeps worker alive for demo
        return true;
      default:
        return false;
    }
  });
}

class WorkmanagerService {
  Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
    AppLogger.info('WorkManager initialized');
  }

  Future<void> scheduleDecryptTask(Map<String, dynamic> payload) async {
    await Workmanager().registerOneOffTask(
      'decrypt_${DateTime.now().millisecondsSinceEpoch}',
      rozgarDecryptTask,
      inputData: payload,
      constraints: Constraints(networkType: NetworkType.notRequired),
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

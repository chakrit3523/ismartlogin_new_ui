import '../core/di/service_locator.dart';

Future<void> bootstrapApp() async {
  await setupServiceLocator();
}

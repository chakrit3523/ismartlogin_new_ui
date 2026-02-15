import 'package:get_it/get_it.dart';

import '../network/network_client.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  if (!sl.isRegistered<NetworkClient>()) {
    sl.registerLazySingleton<NetworkClient>(NetworkClient.new);
  }
}

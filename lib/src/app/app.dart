import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';

import '../features/splashscreen/presentation/pages/splashscreen_screen.dart';
import '../core/presentation/bloc/global_ui_refresh_cubit.dart';

class ISmartLoginApp extends StatelessWidget {
  const ISmartLoginApp({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<GlobalUiRefreshCubit>(
          create: (_) => GlobalUiRefreshCubit(),
        ),
      ],
      child: BlocBuilder<GlobalUiRefreshCubit, int>(
        builder: (_, __) => MaterialApp(
          navigatorKey: navigatorKey,
          title: 'iSmart Login',
          debugShowCheckedModeBanner: false,
          home: SplashscreenScreen(),
        ),
      ),
    );
  }
}

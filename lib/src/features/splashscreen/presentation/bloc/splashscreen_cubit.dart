import 'package:flutter_bloc/flutter_bloc.dart';

import 'splashscreen_state.dart';

class SplashscreenCubit extends Cubit<SplashscreenState> {
  SplashscreenCubit() : super(const SplashscreenState());

  void setLoading(bool value) {
    emit(state.copyWith(isLoading: value));
  }
}

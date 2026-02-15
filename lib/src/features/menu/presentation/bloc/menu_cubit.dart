import 'package:flutter_bloc/flutter_bloc.dart';

import 'menu_state.dart';

class MenuCubit extends Cubit<MenuState> {
  MenuCubit() : super(const MenuState());

  void setLoading(bool value) {
    emit(state.copyWith(isLoading: value));
  }
}

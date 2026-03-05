import 'package:flutter_bloc/flutter_bloc.dart';

import 'protect_state.dart';

class ProtectCubit extends Cubit<ProtectState> {
  ProtectCubit() : super(const ProtectState());

  void setLoading(bool value) {
    emit(state.copyWith(isLoading: value));
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import 'front_state.dart';

class FrontCubit extends Cubit<FrontState> {
  FrontCubit() : super(const FrontState());

  void setLoading(bool value) {
    emit(state.copyWith(isLoading: value));
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import 'outside_state.dart';

class OutsideCubit extends Cubit<OutsideState> {
  OutsideCubit() : super(const OutsideState());

  void setLoading(bool value) {
    emit(state.copyWith(isLoading: value));
  }
}

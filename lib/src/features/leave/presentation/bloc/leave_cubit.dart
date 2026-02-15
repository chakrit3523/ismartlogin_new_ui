import 'package:flutter_bloc/flutter_bloc.dart';

import 'leave_state.dart';

class LeaveCubit extends Cubit<LeaveState> {
  LeaveCubit() : super(const LeaveState());

  void setLoading(bool value) {
    emit(state.copyWith(isLoading: value));
  }
}

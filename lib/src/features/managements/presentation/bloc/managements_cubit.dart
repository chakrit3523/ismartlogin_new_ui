import 'package:flutter_bloc/flutter_bloc.dart';

import 'managements_state.dart';

class ManagementsCubit extends Cubit<ManagementsState> {
  ManagementsCubit() : super(const ManagementsState());

  void setLoading(bool value) {
    emit(state.copyWith(isLoading: value));
  }
}

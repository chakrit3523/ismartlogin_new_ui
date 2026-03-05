import 'package:flutter_bloc/flutter_bloc.dart';

import 'org_state.dart';

class OrgCubit extends Cubit<OrgState> {
  OrgCubit() : super(const OrgState());

  void setLoading(bool value) {
    emit(state.copyWith(isLoading: value));
  }
}

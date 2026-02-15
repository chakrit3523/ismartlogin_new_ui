import 'package:flutter_bloc/flutter_bloc.dart';

import 'sign_state.dart';

class SignCubit extends Cubit<SignState> {
  SignCubit() : super(const SignState());

  void setLoading(bool value) {
    emit(state.copyWith(isLoading: value));
  }
}

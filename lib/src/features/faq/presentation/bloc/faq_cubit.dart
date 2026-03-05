import 'package:flutter_bloc/flutter_bloc.dart';

import 'faq_state.dart';

class FaqCubit extends Cubit<FaqState> {
  FaqCubit() : super(const FaqState());

  void setLoading(bool value) {
    emit(state.copyWith(isLoading: value));
  }
}

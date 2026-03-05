import 'package:flutter_bloc/flutter_bloc.dart';

import 'contact_dev_state.dart';

class ContactDevCubit extends Cubit<ContactDevState> {
  ContactDevCubit() : super(const ContactDevState());

  void setLoading(bool value) {
    emit(state.copyWith(isLoading: value));
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  MapCubit() : super(const MapState());

  void setLoading(bool value) {
    emit(state.copyWith(isLoading: value));
  }
}

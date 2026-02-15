import 'package:flutter_bloc/flutter_bloc.dart';

/// Single cubit used as a bridge while migrating legacy widget-local state
/// to feature-scoped BLoCs.
class GlobalUiRefreshCubit extends Cubit<int> {
  GlobalUiRefreshCubit() : super(0);

  void refresh() => emit(state + 1);
}

import 'package:flutter/material.dart' as m;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'global_ui_refresh_cubit.dart';

export 'package:flutter/material.dart';
export 'package:flutter_bloc/flutter_bloc.dart';

/// Transitional helper: replaces direct setState calls with a BLoC-driven
/// refresh signal while still allowing existing widget state fields to remain.
extension BlocSetStateExtension<T extends m.StatefulWidget> on m.State<T> {
  void blocSetState(m.VoidCallback fn) {
    fn();

    final refreshCubit = _findRefreshCubit();
    refreshCubit?.refresh();

    if (!mounted) {
      return;
    }

    final element = context as m.Element;
    if (!element.mounted) {
      return;
    }

    // Rebuild this widget state directly to preserve legacy behavior
    // while migration to feature-scoped BLoCs is still in progress.
    // ignore: invalid_use_of_protected_member
    element.markNeedsBuild();
  }

  GlobalUiRefreshCubit? _findRefreshCubit() {
    try {
      return BlocProvider.of<GlobalUiRefreshCubit>(context, listen: false);
    } catch (_) {
      return null;
    }
  }
}

import 'package:equatable/equatable.dart';

class ProtectState extends Equatable {
  const ProtectState({this.isLoading = false});

  final bool isLoading;

  ProtectState copyWith({bool? isLoading}) {
    return ProtectState(
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => <Object>[isLoading];
}

import 'package:equatable/equatable.dart';

class FrontState extends Equatable {
  const FrontState({this.isLoading = false});

  final bool isLoading;

  FrontState copyWith({bool? isLoading}) {
    return FrontState(
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => <Object>[isLoading];
}

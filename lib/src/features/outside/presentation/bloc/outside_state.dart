import 'package:equatable/equatable.dart';

class OutsideState extends Equatable {
  const OutsideState({this.isLoading = false});

  final bool isLoading;

  OutsideState copyWith({bool? isLoading}) {
    return OutsideState(
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => <Object>[isLoading];
}

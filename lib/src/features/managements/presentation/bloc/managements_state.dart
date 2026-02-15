import 'package:equatable/equatable.dart';

class ManagementsState extends Equatable {
  const ManagementsState({this.isLoading = false});

  final bool isLoading;

  ManagementsState copyWith({bool? isLoading}) {
    return ManagementsState(
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => <Object>[isLoading];
}

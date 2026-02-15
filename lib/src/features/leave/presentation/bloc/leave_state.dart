import 'package:equatable/equatable.dart';

class LeaveState extends Equatable {
  const LeaveState({this.isLoading = false});

  final bool isLoading;

  LeaveState copyWith({bool? isLoading}) {
    return LeaveState(
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => <Object>[isLoading];
}

import 'package:equatable/equatable.dart';

class SignState extends Equatable {
  const SignState({this.isLoading = false});

  final bool isLoading;

  SignState copyWith({bool? isLoading}) {
    return SignState(
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => <Object>[isLoading];
}

import 'package:equatable/equatable.dart';

class SplashscreenState extends Equatable {
  const SplashscreenState({this.isLoading = false});

  final bool isLoading;

  SplashscreenState copyWith({bool? isLoading}) {
    return SplashscreenState(
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => <Object>[isLoading];
}

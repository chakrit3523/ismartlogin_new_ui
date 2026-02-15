import 'package:equatable/equatable.dart';

class FaqState extends Equatable {
  const FaqState({this.isLoading = false});

  final bool isLoading;

  FaqState copyWith({bool? isLoading}) {
    return FaqState(
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => <Object>[isLoading];
}

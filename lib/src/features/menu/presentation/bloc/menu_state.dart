import 'package:equatable/equatable.dart';

class MenuState extends Equatable {
  const MenuState({this.isLoading = false});

  final bool isLoading;

  MenuState copyWith({bool? isLoading}) {
    return MenuState(
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => <Object>[isLoading];
}

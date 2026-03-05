import 'package:equatable/equatable.dart';

class ProfileState extends Equatable {
  const ProfileState({this.isLoading = false});

  final bool isLoading;

  ProfileState copyWith({bool? isLoading}) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => <Object>[isLoading];
}

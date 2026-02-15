import 'package:equatable/equatable.dart';

class OrgState extends Equatable {
  const OrgState({this.isLoading = false});

  final bool isLoading;

  OrgState copyWith({bool? isLoading}) {
    return OrgState(
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => <Object>[isLoading];
}

import 'package:equatable/equatable.dart';

class ContactDevState extends Equatable {
  const ContactDevState({this.isLoading = false});

  final bool isLoading;

  ContactDevState copyWith({bool? isLoading}) {
    return ContactDevState(
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => <Object>[isLoading];
}

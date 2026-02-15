import 'package:equatable/equatable.dart';

class HistoryState extends Equatable {
  const HistoryState({this.isLoading = false});

  final bool isLoading;

  HistoryState copyWith({bool? isLoading}) {
    return HistoryState(
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => <Object>[isLoading];
}

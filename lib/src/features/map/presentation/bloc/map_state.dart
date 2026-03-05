import 'package:equatable/equatable.dart';

class MapState extends Equatable {
  const MapState({this.isLoading = false});

  final bool isLoading;

  MapState copyWith({bool? isLoading}) {
    return MapState(
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => <Object>[isLoading];
}

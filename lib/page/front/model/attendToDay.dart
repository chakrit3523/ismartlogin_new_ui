class ItemsAttandToDay {
  final String STATUS;
  final String START_TIME;
  final String START_NOTE;
  final String START_STATUS;
  final String END_TIME;
  final String END_NOTE;
  final String END_STATUS;

  ItemsAttandToDay({
    required this.STATUS,
    required this.START_TIME,
    required this.START_NOTE,
    required this.START_STATUS,
    required this.END_TIME,
    required this.END_NOTE,
    required this.END_STATUS,
  });

  factory ItemsAttandToDay.fromJson(Map<String, dynamic> json) {
    return ItemsAttandToDay(
      STATUS: json['status']?.toString() ?? '',
      START_TIME: json['start_time']?.toString() ?? '',
      START_NOTE: json['start_note']?.toString() ?? '',
      START_STATUS: json['start_status']?.toString() ?? '',
      END_TIME: json['end_time']?.toString() ?? '',
      END_NOTE: json['end_note']?.toString() ?? '',
      END_STATUS: json['end_status']?.toString() ?? '',
    );
  }
}

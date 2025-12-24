class ItemsAttandOutsideToDay {
  final String CID;
  final String STATUS;
  final String CREATE_DATE;
  final String START_TIME;
  final String START_NOTE;
  final String START_IMAGES;
  final String START_STATUS;
  final String END_TIME;
  final String END_NOTE;
  final String END_IMAGES;
  final String END_STATUS;

  ItemsAttandOutsideToDay({
    required this.CID,
    required this.STATUS,
    required this.CREATE_DATE,
    required this.START_TIME,
    required this.START_NOTE,
    required this.START_IMAGES,
    required this.START_STATUS,
    required this.END_TIME,
    required this.END_NOTE,
    required this.END_IMAGES,
    required this.END_STATUS,
  });

  factory ItemsAttandOutsideToDay.fromJson(Map<String, dynamic> json) {
    return ItemsAttandOutsideToDay(
      CID: json['cid'],
      STATUS: json['status'],
      CREATE_DATE: json['create_date'],
      START_TIME: json['start_time'],
      START_NOTE: json['start_note'],
      START_IMAGES: json['start_images'],
      START_STATUS: json['start_status'],
      END_TIME: json['end_time'],
      END_NOTE: json['end_note'],
      END_IMAGES: json['end_images'],
      END_STATUS: json['end_status'],
    );
  }
}

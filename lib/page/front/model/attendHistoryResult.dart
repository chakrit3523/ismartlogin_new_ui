class ItemsAttendHistoryResult {
  final String TIME;
  final String TIME_STATUS;
  final String TIME_ID_NAME;
  final String STATUS;
  final String IMAGES;
  final String LAT;
  final String LNG;
  final String NOTE;
  final String DETAIL;
  final String CID;

  ItemsAttendHistoryResult({
    required this.TIME,
    required this.TIME_STATUS,
    required this.TIME_ID_NAME,
    required this.STATUS,
    required this.IMAGES,
    required this.LAT,
    required this.LNG,
    required this.NOTE,
    required this.DETAIL,
    required this.CID,
  });

  factory ItemsAttendHistoryResult.fromJson(Map<String, dynamic> json) {
    return ItemsAttendHistoryResult(
      TIME: json['time']?.toString() ?? '',
      TIME_STATUS: json['time_status']?.toString() ?? '',
      TIME_ID_NAME: json['time_id_name']?.toString() ?? '',
      STATUS: json['status']?.toString() ?? '',
      IMAGES: json['images']?.toString() ?? '',
      LAT: json['lat']?.toString() ?? '',
      LNG: json['lng']?.toString() ?? '',
      NOTE: json['note']?.toString() ?? '',
      DETAIL: json['detail']?.toString() ?? '',
      CID: json['cid']?.toString() ?? '',
    );
  }
}

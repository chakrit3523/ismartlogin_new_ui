class ItemsAttendEndResult {
  final String ID;
  final String UID;
  final String UPLOADKEY;
  final String STATUS;
  final String MSG;

  ItemsAttendEndResult({
    required this.ID,
    required this.UID,
    required this.UPLOADKEY,
    required this.STATUS,
    required this.MSG,
  });

  factory ItemsAttendEndResult.fromJson(Map<String, dynamic> json) {
    return ItemsAttendEndResult(
      ID: json['id'],
      UID: json['uid'],
      UPLOADKEY: json['uploadKey'],
      STATUS: json['status'],
      MSG: json['msg'],
    );
  }
}

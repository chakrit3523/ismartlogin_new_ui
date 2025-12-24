class ItemsAttandOutsideStartResult {
  final String UID;
  final String UPLOADKEY;
  final String STATUS;
  final String MSG;

  ItemsAttandOutsideStartResult({
    required this.UID,
    required this.UPLOADKEY,
    required this.STATUS,
    required this.MSG,
  });

  factory ItemsAttandOutsideStartResult.fromJson(Map<String, dynamic> json) {
    return ItemsAttandOutsideStartResult(
      UID: json['uid'],
      UPLOADKEY: json['uploadKey'],
      STATUS: json['status'],
      MSG: json['msg'],
    );
  }
}

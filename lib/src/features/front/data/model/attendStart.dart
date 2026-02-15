class ItemsAttandStartResult {
  final String UID;
  final String UPLOADKEY;
  final String STATUS;
  final String MSG;

  ItemsAttandStartResult({
    required this.UID,
    required this.UPLOADKEY,
    required this.STATUS,
    required this.MSG,
  });

  factory ItemsAttandStartResult.fromJson(Map<String, dynamic> json) {
    return ItemsAttandStartResult(
      UID: json['uid'],
      UPLOADKEY: json['uploadKey'],
      STATUS: json['status'],
      MSG: json['msg'],
    );
  }
}

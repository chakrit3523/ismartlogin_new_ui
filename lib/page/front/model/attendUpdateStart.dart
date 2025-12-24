class ItemsUpdateAttandStartResult {
  final String ID;
  final String STATUS;
  final String MSG;

  ItemsUpdateAttandStartResult({
    required this.ID,
    required this.STATUS,
    required this.MSG,
  });

  factory ItemsUpdateAttandStartResult.fromJson(Map<String, dynamic> json) {
    return ItemsUpdateAttandStartResult(
      ID: json['id'],
      STATUS: json['status'],
      MSG: json['msg'],
    );
  }
}

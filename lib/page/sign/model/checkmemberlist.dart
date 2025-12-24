class ItemsCheckMemberResult {
  final String MSG;
  final String STATUS;

  ItemsCheckMemberResult({
    required this.MSG,
    required this.STATUS,
  });

  factory ItemsCheckMemberResult.fromJson(Map<String, dynamic> json) {
    return ItemsCheckMemberResult(
      MSG: json['msg'],
      STATUS: json['status'],
    );
  }
}

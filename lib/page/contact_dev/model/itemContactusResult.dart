class ItemContactusResult {
  final String MSG;
  final bool STATUS;

  ItemContactusResult({
    required this.MSG,
    required this.STATUS,
  });

  factory ItemContactusResult.fromJson(Map<String, dynamic> json) {
    return ItemContactusResult(
      MSG: json['msg'],
      STATUS: json['status'],
    );
  }
}

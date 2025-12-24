class ItemsMemberStatusManage {
  final String MSG;
  final bool STATUS;
  final String RESULT;

  ItemsMemberStatusManage({
    required this.MSG,
    required this.STATUS,
    required this.RESULT,
  });

  factory ItemsMemberStatusManage.fromJson(Map<String, dynamic> json) {
    return ItemsMemberStatusManage(
      MSG: json['msg'],
      STATUS: json['status'],
      RESULT: json['result'],
    );
  }
}

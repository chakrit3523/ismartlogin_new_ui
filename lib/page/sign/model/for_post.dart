class ItemsMemberResultList {
  final String MSG;
  final String UPLOADKEY;
  final String RESULT;

  ItemsMemberResultList({
    required this.MSG,
    required this.UPLOADKEY,
    required this.RESULT,
  });

  factory ItemsMemberResultList.fromJson(Map<String, dynamic> json) {
    return ItemsMemberResultList(
      MSG: json['msg'],
      UPLOADKEY: json['uploadKey'],
      RESULT: json['result'],
    );
  }
}

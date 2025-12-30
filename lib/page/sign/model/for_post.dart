class ItemsMemberResultList {
  final String MSG;
  final String UPLOADKEY;
  final String RESULT;
  final String ID;

  ItemsMemberResultList({
    required this.MSG,
    required this.UPLOADKEY,
    required this.RESULT,
    this.ID = '',
  });

  factory ItemsMemberResultList.fromJson(Map<String, dynamic> json) {
    return ItemsMemberResultList(
      MSG: json['msg'],
      UPLOADKEY: json['uploadKey'],
      RESULT: json['result'],
      ID: json['id'] ?? '',
    );
  }
}

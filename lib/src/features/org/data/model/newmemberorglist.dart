class ItemsResultUpdateNewMember {
  final String MSG;
  final String RESULT;

  ItemsResultUpdateNewMember({
    required this.MSG,
    required this.RESULT,
  });

  factory ItemsResultUpdateNewMember.fromJson(Map<String, dynamic> json) {
    return ItemsResultUpdateNewMember(
      MSG: json['msg'],
      RESULT: json['result'],
    );
  }
}

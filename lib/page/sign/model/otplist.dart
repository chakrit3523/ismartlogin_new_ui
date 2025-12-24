class ItemsOTPList {
  final String MSG;
  final String RESULT;

  ItemsOTPList({
    required this.MSG,
    required this.RESULT,
  });

  factory ItemsOTPList.fromJson(Map<String, dynamic> json) {
    return ItemsOTPList(
      MSG: json['msg'],
      RESULT: json['result'],
    );
  }
}

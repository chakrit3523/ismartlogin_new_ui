import 'package:ismart_login/page/sign/model/memberlist.dart';

class ItemsMemberResult {
  final String MSG;
  final List<ItemsMemberList> RESULT;

  ItemsMemberResult({
    required this.MSG,
    required this.RESULT,
  });

  factory ItemsMemberResult.fromJson(Map<String, dynamic> json) {
    return ItemsMemberResult(
      MSG: json['msg'],
      RESULT: List.from(json['result'].map((m) => ItemsMemberList.fromJson(m))),
    );
  }
}

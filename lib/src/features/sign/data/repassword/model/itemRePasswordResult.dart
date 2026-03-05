import 'package:ismart_login/src/features/sign/presentation/pages/repassword/model/itemRePasswordResultDetail.dart';

class ItemsRePasswordMemberResult {
  final String MSG;
  final bool STATUS;
  final List<ItemsRePasswordMemberResultDetail> RESULT;

  ItemsRePasswordMemberResult({
    required this.MSG,
    required this.STATUS,
    required this.RESULT,
  });

  factory ItemsRePasswordMemberResult.fromJson(Map<String, dynamic> json) {
    return ItemsRePasswordMemberResult(
      MSG: json['msg'],
      STATUS: json['status'],
      RESULT: List.from(json['result']
          .map((m) => ItemsRePasswordMemberResultDetail.fromJson(m))),
    );
  }
}

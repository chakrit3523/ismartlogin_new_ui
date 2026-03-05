import 'package:ismart_login/src/features/front/presentation/pages/model/orglist.dart';

class ItemsOrgResult {
  final String MSG;
  final List<ItemsOrgList> RESULT;

  ItemsOrgResult({
    required this.MSG,
    required this.RESULT,
  });

  factory ItemsOrgResult.fromJson(Map<String, dynamic> json) {
    return ItemsOrgResult(
      MSG: json['msg'],
      RESULT: List.from(json['result'].map((m) => ItemsOrgList.fromJson(m))),
    );
  }
}

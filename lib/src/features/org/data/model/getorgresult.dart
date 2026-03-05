import 'package:ismart_login/src/features/org/presentation/pages/model/getorglist.dart';

class ItemsGetOrgResult {
  final String MSG;
  final List<ItemsGetOrgList> RESULT;

  ItemsGetOrgResult({
    required this.MSG,
    required this.RESULT,
  });

  factory ItemsGetOrgResult.fromJson(Map<String, dynamic> json) {
    return ItemsGetOrgResult(
      MSG: json['msg'],
      RESULT: List.from(json['result'].map((m) => ItemsGetOrgList.fromJson(m))),
    );
  }
}

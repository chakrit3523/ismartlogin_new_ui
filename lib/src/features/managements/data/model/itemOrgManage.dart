import 'package:ismart_login/src/features/managements/presentation/pages/model/itemOrgResultManage.dart';

class ItemsOrgPostManage {
  final String MSG;
  final bool STATUS;
  final String? ID;

  ItemsOrgPostManage({
    required this.MSG,
    required this.STATUS,
    this.ID,
  });

  factory ItemsOrgPostManage.fromJson(Map<String, dynamic> json) {
    return ItemsOrgPostManage(
      MSG: json['msg'],
      STATUS: json['status'],
      ID: json['id']?.toString(),
    );
  }
}

class ItemsOrgSuspendManage {
  final String MSG;
  final bool STATUS;

  ItemsOrgSuspendManage({
    required this.MSG,
    required this.STATUS,
  });

  factory ItemsOrgSuspendManage.fromJson(Map<String, dynamic> json) {
    return ItemsOrgSuspendManage(
      MSG: json['msg'],
      STATUS: json['status'],
    );
  }
}

class ItemsOrgGetManage {
  final String MSG;
  final bool STATUS;
  final List<ItemsOrgResultManage> RESULT;

  ItemsOrgGetManage({
    required this.MSG,
    required this.STATUS,
    required this.RESULT,
  });

  factory ItemsOrgGetManage.fromJson(Map<String, dynamic> json) {
    return ItemsOrgGetManage(
      MSG: json['msg'],
      STATUS: json['status'],
      RESULT: List.from(
          json['result'].map((m) => ItemsOrgResultManage.fromJson(m))),
    );
  }
}

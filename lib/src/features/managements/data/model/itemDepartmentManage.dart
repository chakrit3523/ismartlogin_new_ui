import 'package:ismart_login/src/features/managements/presentation/pages/model/itemDepartmentResultManage.dart';

class ItemsDepartmentManage {
  final String MSG;
  final bool STATUS;
  final List<ItemsDepartmentResultManage> RESULT;

  ItemsDepartmentManage({
    required this.MSG,
    required this.STATUS,
    required this.RESULT,
  });

  factory ItemsDepartmentManage.fromJson(Map<String, dynamic> json) {
    return ItemsDepartmentManage(
      MSG: json['msg'],
      STATUS: json['status'],
      RESULT: List.from(
          json['result'].map((m) => ItemsDepartmentResultManage.fromJson(m))),
    );
  }
}

class ItemsDepartmentManagePostUpdate {
  final String MSG;
  final bool STATUS;

  ItemsDepartmentManagePostUpdate({
    required this.MSG,
    required this.STATUS,
  });

  factory ItemsDepartmentManagePostUpdate.fromJson(Map<String, dynamic> json) {
    return ItemsDepartmentManagePostUpdate(
      MSG: json['msg'],
      STATUS: json['status'],
    );
  }
}

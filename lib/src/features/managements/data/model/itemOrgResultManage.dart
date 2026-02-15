class ItemsOrgResultManage {
  final String ID;
  final String ORG_ID;
  final String SUBJECT;
  final String CREATE_BY;
  final bool ACTIVE;
  final String ORG_CREATE;
  final String INVITE;
  final String HISTORY;
  final String NOTI;
  final String OT;
  final String LOGUT_STATUS;
  final String TIME_STATUS;
  final String LEAVE_CANCEL_STATUS;

  ItemsOrgResultManage(
      {required this.ID,
      required this.ORG_ID,
      required this.SUBJECT,
      required this.CREATE_BY,
      required this.ACTIVE,
      required this.ORG_CREATE,
      required this.INVITE,
      required this.HISTORY,
      required this.NOTI,
      required this.OT,
      required this.LOGUT_STATUS,
      required this.TIME_STATUS,
      required this.LEAVE_CANCEL_STATUS});

  factory ItemsOrgResultManage.fromJson(Map<String, dynamic> json) {
    return ItemsOrgResultManage(
        ID: json['id']?.toString() ?? '',
        ORG_ID: json['org_id']?.toString() ?? '',
        SUBJECT: json['subject']?.toString() ?? '',
        CREATE_BY: json['create_by']?.toString() ?? '',
        ACTIVE: json['active_org'] ?? false,
        ORG_CREATE: json['org_create']?.toString() ?? '',
        INVITE: json['invite']?.toString() ?? '',
        HISTORY: json['history']?.toString() ?? '',
        NOTI: json['noti']?.toString() ?? '',
        OT: json['ot']?.toString() ?? '',
        LOGUT_STATUS: json['logout']?.toString() ?? '',
        TIME_STATUS: json['time_status']?.toString() ?? '',
        LEAVE_CANCEL_STATUS: json['leave_cancel_status']?.toString() ?? '');
  }
}

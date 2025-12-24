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

  ItemsOrgResultManage({
    required this.ID,
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
    required this.LEAVE_CANCEL_STATUS
  });

  factory ItemsOrgResultManage.fromJson(Map<String, dynamic> json) {
    return ItemsOrgResultManage(
      ID: json['id'],
      ORG_ID: json['org_id'],
      SUBJECT: json['subject'],
      CREATE_BY: json['create_by'],
      ACTIVE: json['active_org'],
      ORG_CREATE: json['org_create'],
      INVITE: json['invite'],
      HISTORY: json['history'],
      NOTI: json['noti'],
      OT: json['ot'],
      LOGUT_STATUS: json['logout'],
      TIME_STATUS: json['time_status'],
      LEAVE_CANCEL_STATUS: json['leave_cancel_status']
    );
  }
}

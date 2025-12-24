class ItemsMemberResultManage {
  final String? ID;
  final String? FULLNAME;
  final String? NICKNAME;
  final String? PHONE;
  final String? AVATAR;
  final String? ORG_ID;
  final String? ORG_NAME;
  final String? ORG_SUB_ID;
  final String? ORG_SUB_NAME;
  final String? TIME_ID;
  final String? TIME_ID_NAME;
  final String? STATUS;
  final String? STAT;
  final String? SUPER_STATUS;
  final String? ADMIN_BRANCH_ID;
  final String? MEMBER_TYPE;
  final String? HISTORY;
  final String? NOTI;
  final String? LEAVE;
  final String? LEAVE_MEMBER;
  final String? TIME_STATUS;
  final String? NAME_BRANCH;

  ItemsMemberResultManage({
    this.ID,
    this.FULLNAME,
    this.NICKNAME,
    this.PHONE,
    this.AVATAR,
    this.ORG_ID,
    this.ORG_NAME,
    this.ORG_SUB_ID,
    this.ORG_SUB_NAME,
    this.TIME_ID,
    this.TIME_ID_NAME,
    this.STATUS,
    this.STAT,
    this.MEMBER_TYPE,
    this.HISTORY,
    this.NOTI,
    this.LEAVE,
    this.LEAVE_MEMBER,
    this.TIME_STATUS,
    this.SUPER_STATUS,
    this.ADMIN_BRANCH_ID,
    this.NAME_BRANCH,
  });

  factory ItemsMemberResultManage.fromJson(Map<String, dynamic> json) {
    return ItemsMemberResultManage(
      ID: json['id']?.toString() ?? '',
      FULLNAME: json['fullname']?.toString() ?? '',
      NICKNAME: json['nickname']?.toString() ?? '',
      PHONE: json['phone']?.toString() ?? '',
      AVATAR: json['avatar']?.toString() ?? '',
      ORG_ID: json['org_id']?.toString() ?? '',
      ORG_NAME: json['org_name']?.toString() ?? '',
      ORG_SUB_ID: json['org_sub_id']?.toString() ?? '',
      ORG_SUB_NAME: json['org_sub_name']?.toString() ?? '',
      TIME_ID: json['time_id']?.toString() ?? '',
      TIME_ID_NAME: json['time_id_name']?.toString() ?? '',
      MEMBER_TYPE: json['member_type']?.toString() ?? '',
      STATUS: json['status']?.toString() ?? '',
      SUPER_STATUS: json['super_status']?.toString() ?? '',
      ADMIN_BRANCH_ID: json['admin_branch_id']?.toString() ?? '',
      STAT: json['stat']?.toString() ?? '',
      HISTORY: json['history']?.toString() ?? '',
      NOTI: json['noti']?.toString() ?? '',
      LEAVE: json['leave']?.toString() ?? '',
      LEAVE_MEMBER: json['leave_member']?.toString() ?? '',
      TIME_STATUS: json['time_status']?.toString() ?? '',
      NAME_BRANCH: json['name_branch']?.toString() ?? '',
    );
  }
}

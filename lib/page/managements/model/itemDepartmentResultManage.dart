class ItemsDepartmentResultManage {
  final String ID;
  final String PARENT_ID;
  final String INVITE_CODE;
  final String SUBJECT;
  final String LATITUDE;
  final String LONGTITUDE;
  final String RADIUS;
  final String CREATE_DATE;
  final String UPDATE_DATE;
  final String STATUS;
  final String NOTI;
  final String SEQ;
  final String TIME_ID;

  ItemsDepartmentResultManage({
    required this.ID,
    required this.PARENT_ID,
    required this.INVITE_CODE,
    required this.SUBJECT,
    required this.LATITUDE,
    required this.LONGTITUDE,
    required this.RADIUS,
    required this.CREATE_DATE,
    required this.UPDATE_DATE,
    required this.NOTI,
    required this.STATUS,
    required this.SEQ,
    required this.TIME_ID,
  });

  factory ItemsDepartmentResultManage.fromJson(Map<String, dynamic> json) {
    return ItemsDepartmentResultManage(
      ID: json['id'],
      PARENT_ID: json['parent_id'],
      INVITE_CODE: json['invite_code'],
      SUBJECT: json['subject'],
      LATITUDE: json['latitude'],
      LONGTITUDE: json['longitude'],
      RADIUS: json['radius'],
      CREATE_DATE: json['create_date'],
      UPDATE_DATE: json['update_date'],
      STATUS: json['status'],
      NOTI: json['noti'],
      SEQ: json['seq'],
      TIME_ID: json['time_id'],
    );
  }
}

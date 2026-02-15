class ItemsTimeResultManage {
  final String ID;
  final String ORG_ID;
  final String SUBJECT;
  final String DESCRIPTION;
  final String CREATE_DATE;
  final String STATUS;

  ItemsTimeResultManage({
    required this.ID,
    required this.ORG_ID,
    required this.SUBJECT,
    required this.DESCRIPTION,
    required this.CREATE_DATE,
    required this.STATUS,
  });

  factory ItemsTimeResultManage.fromJson(Map<String, dynamic> json) {
    return ItemsTimeResultManage(
      ID: json['id']?.toString() ?? '',
      ORG_ID: json['org_id']?.toString() ?? '',
      SUBJECT: json['subject']?.toString() ?? '',
      DESCRIPTION: json['description']?.toString() ?? '',
      CREATE_DATE: json['create_date']?.toString() ?? '',
      STATUS: json['status']?.toString() ?? '',
    );
  }
}

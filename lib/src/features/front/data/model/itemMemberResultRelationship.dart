class ItemsMemberResultRelationship {
  final String ID;
  final String UID;
  final String AVATAR;
  final String ORG_ID;
  final String ORG_SUB_ID;
  final String TIME_ID;
  final String TYPE;

  ItemsMemberResultRelationship({
    required this.ID,
    required this.UID,
    required this.AVATAR,
    required this.ORG_ID,
    required this.ORG_SUB_ID,
    required this.TIME_ID,
    required this.TYPE,
  });

  factory ItemsMemberResultRelationship.fromJson(Map<String, dynamic> json) {
    return ItemsMemberResultRelationship(
      ID: json['id']?.toString() ?? '',
      UID: json['uid']?.toString() ?? '',
      AVATAR: json['avatar']?.toString() ?? '',
      ORG_ID: json['org_id']?.toString() ?? '',
      ORG_SUB_ID: json['org_sub_id']?.toString() ?? '',
      TIME_ID: json['time_id']?.toString() ?? '',
      TYPE: json['type']?.toString() ?? '',
    );
  }
}

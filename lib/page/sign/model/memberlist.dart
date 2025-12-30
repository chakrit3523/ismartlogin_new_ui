class ItemsMemberList {
  final String ID;
  final String USERNAME;
  final String PASSWORD;
  final String FULLNAME;
  final String AVATAR;
  final String ORG_ID;
  final String ORG_NAME;
  final String PHONE;
  final String TIME_ID;

  ItemsMemberList({
    required this.ID,
    required this.USERNAME,
    required this.PASSWORD,
    required this.FULLNAME,
    required this.AVATAR,
    required this.ORG_ID,
    required this.ORG_NAME,
    required this.PHONE,
    required this.TIME_ID,
  });

  factory ItemsMemberList.fromJson(Map<String, dynamic> json) {
    return ItemsMemberList(
      ID: json['id'] ?? '',
      USERNAME: json['username'] ?? '',
      PASSWORD: json['password'] ?? '',
      FULLNAME: json['fullname'] ?? '',
      AVATAR: json['avatar'] ?? '',
      ORG_ID: json['org_id'] ?? '',
      ORG_NAME: json['org_name'] ?? '',
      PHONE: json['phone'] ?? '',
      TIME_ID: json['time_id'] ?? '',
    );
  }
}

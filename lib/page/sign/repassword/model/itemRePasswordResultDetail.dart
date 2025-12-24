class ItemsRePasswordMemberResultDetail {
  final String UID;
  final String USERNAME;
  final String PHONE;
  final String FULLNAME;
  final String NICKNAME;
  final String AVATAR;

  ItemsRePasswordMemberResultDetail({
    required this.UID,
    required this.USERNAME,
    required this.PHONE,
    required this.FULLNAME,
    required this.NICKNAME,
    required this.AVATAR,
  });

  factory ItemsRePasswordMemberResultDetail.fromJson(
      Map<String, dynamic> json) {
    return ItemsRePasswordMemberResultDetail(
      UID: json['uid'],
      USERNAME: json['username'],
      PHONE: json['phone'],
      FULLNAME: json['fullname'],
      NICKNAME: json['nickname'],
      AVATAR: json['avatar'],
    );
  }
}

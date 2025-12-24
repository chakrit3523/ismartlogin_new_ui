class ItemsSwitchOrg {
  final String MSG;
  final String STATUS;

  ItemsSwitchOrg({
    required this.MSG,
    required this.STATUS,
  });

  factory ItemsSwitchOrg.fromJson(Map<String, dynamic> json) {
    return ItemsSwitchOrg(
      MSG: json['msg'],
      STATUS: json['status'],
    );
  }
}

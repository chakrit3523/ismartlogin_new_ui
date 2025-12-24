class ItemsProtect {
  final String KEYINVITE;
  final String STATUS;

  ItemsProtect({
    required this.KEYINVITE,
    required this.STATUS,
  });

  factory ItemsProtect.fromJson(Map<String, dynamic> json) {
    return ItemsProtect(
      KEYINVITE: json['keyinvite'],
      STATUS: json['status'],
    );
  }
}

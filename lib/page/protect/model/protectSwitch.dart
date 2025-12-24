class ItemsProtectSwitch {
  final String id;
  final bool status;
  final String createDate;

  ItemsProtectSwitch({
    required this.id,
    required this.status,
    required this.createDate,
  });

  factory ItemsProtectSwitch.fromJson(Map<String, dynamic> json) {
    return ItemsProtectSwitch(
      id: json['id']?.toString() ?? '', // ✅ ป้องกัน null
      status: json['status'] == true || 
              json['status'] == '1' || 
              json['status'] == 1,       // ✅ รองรับ bool, string, int
      createDate: json['create_date']?.toString() ?? '', // ✅ ป้องกัน null
    );
  }
}
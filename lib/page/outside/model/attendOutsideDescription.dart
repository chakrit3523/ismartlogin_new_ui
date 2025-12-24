class ItemsAttendOutsideDetail {
  final String TOPIC;
  final String DESCRIPTION;

  ItemsAttendOutsideDetail({
    required this.TOPIC,
    required this.DESCRIPTION,
  });

  factory ItemsAttendOutsideDetail.fromJson(Map<String, dynamic> json) {
    return ItemsAttendOutsideDetail(
      TOPIC: json['topic'],
      DESCRIPTION: json['description'],
    );
  }
}

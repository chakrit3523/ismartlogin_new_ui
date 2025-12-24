class ItemsAttendOutsideDetailPop {
  final String TOPIC;
  final String DESCRIPTION;

  ItemsAttendOutsideDetailPop({
    required this.TOPIC,
    required this.DESCRIPTION,
  });

  factory ItemsAttendOutsideDetailPop.fromJson(Map<String, dynamic> json) {
    return ItemsAttendOutsideDetailPop(
      TOPIC: json['topic'],
      DESCRIPTION: json['description'],
    );
  }
}

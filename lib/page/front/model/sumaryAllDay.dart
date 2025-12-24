class ItemsSummaryAllDay {
  final String CID;
  final String CREATE_DATE;
  final String CREATE_DATE_TH;
  final String ONTIME;
  final String LATE;
  final String ABSENCE;
  final String LEAVE;

  ItemsSummaryAllDay({
    required this.CID,
    required this.CREATE_DATE,
    required this.CREATE_DATE_TH,
    required this.ONTIME,
    required this.LATE,
    required this.ABSENCE,
    required this.LEAVE,
  });

  factory ItemsSummaryAllDay.fromJson(Map<String, dynamic> json) {
    return ItemsSummaryAllDay(
      CID: json['cid'],
      CREATE_DATE: json['create_date'],
      CREATE_DATE_TH: json['create_date_th'],
      ONTIME: json['ontime'],
      LATE: json['late'],
      ABSENCE: json['absence'],
      LEAVE: json['leave'],
    );
  }
}

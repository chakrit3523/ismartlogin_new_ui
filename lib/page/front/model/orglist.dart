class ItemsOrgList {
  final String ID;
  final String SUBJECT;
  final String DESCRIPTION;
  final String DATE_WORKING;
  final String TIME_INSITE;
  final String TIME_OUTSITE;
  final String LATITUDE;
  final String LONGITUDE;

  ItemsOrgList({
    required this.ID,
    required this.SUBJECT,
    required this.DESCRIPTION,
    required this.DATE_WORKING,
    required this.TIME_INSITE,
    required this.TIME_OUTSITE,
    required this.LATITUDE,
    required this.LONGITUDE,
  });

  factory ItemsOrgList.fromJson(Map<String, dynamic> json) {
    return ItemsOrgList(
      ID: json['id']?.toString() ?? '',
      SUBJECT: json['subject']?.toString() ?? '',
      DESCRIPTION: json['description']?.toString() ?? '',
      DATE_WORKING: json['date_working']?.toString() ?? '',
      TIME_INSITE: json['time_insite']?.toString() ?? '',
      TIME_OUTSITE: json['time_outsite']?.toString() ?? '',
      LATITUDE: json['latitude']?.toString() ?? '',
      LONGITUDE: json['longitude']?.toString() ?? '',
    );
  }
}

class ItemsGetOrgList {
  final String ID;
  final String SUBJECT;
  final String INVITE_CODE;
  final String DESCRIPTION;
  final String DATE_WORKING;
  final String TIME_INSITE;
  final String TIME_OUTSITE;
  final String LATITUDE;
  final String LONGITUDE;

  ItemsGetOrgList({
    required this.ID,
    required this.SUBJECT,
    required this.INVITE_CODE,
    required this.DESCRIPTION,
    required this.DATE_WORKING,
    required this.TIME_INSITE,
    required this.TIME_OUTSITE,
    required this.LATITUDE,
    required this.LONGITUDE,
  });

  factory ItemsGetOrgList.fromJson(Map<String, dynamic> json) {
    return ItemsGetOrgList(
      ID: json['id'],
      SUBJECT: json['subject'],
      INVITE_CODE: json['invite_code'],
      DESCRIPTION: json['description'],
      DATE_WORKING: json['date_working'],
      TIME_INSITE: json['time_insite'],
      TIME_OUTSITE: json['time_outsite'],
      LATITUDE: json['latitude'],
      LONGITUDE: json['longitude'],
    );
  }
}

class ItemsMyHistory {
  final String ID;
  final String CID;
  final String UID;
  final String CREATE_DATE_TH;
  final String START_TIME;
  final String START_IMAGE;
  final String START_IMAGE_SMALL;
  final String START_NOTE;
  final String START_STATUS;
  final String START_ADDRESS;
  final String START_LATITUDE;
  final String START_LONGITUDE;
  final String START_LOCATION_STATUS;
  final String START_LOCATION_SUB_STATUS;
  final String END_TIME;
  final String END_IMAGE;
  final String END_IMAGE_SMALL;
  final String END_NOTE;
  final String END_STATUS;
  final String ORG_SUB_NAME;

  ItemsMyHistory({
    required this.ID,
    required this.CID,
    required this.UID,
    required this.CREATE_DATE_TH,
    required this.START_TIME,
    required this.START_IMAGE,
    required this.START_IMAGE_SMALL,
    required this.START_NOTE,
    required this.START_STATUS,
    required this.START_ADDRESS,
    required this.START_LATITUDE,
    required this.START_LONGITUDE,
    required this.START_LOCATION_STATUS,
    required this.START_LOCATION_SUB_STATUS,
    required this.END_TIME,
    required this.END_IMAGE,
    required this.END_IMAGE_SMALL,
    required this.END_NOTE,
    required this.END_STATUS,
    required this.ORG_SUB_NAME,
  });

  factory ItemsMyHistory.fromJson(Map<String, dynamic> json) {
    return ItemsMyHistory(
      ID: json['id']?.toString() ?? '',
      CID: json['cid']?.toString() ?? '',
      UID: json['uid']?.toString() ?? '',
      CREATE_DATE_TH: json['create_date_th']?.toString() ?? '',
      START_TIME: json['start_time']?.toString() ?? '',
      START_IMAGE: json['start_image']?.toString() ?? '',
      // Use start_image instead of tmp path (start_image_small)
      START_IMAGE_SMALL: json['start_image']?.toString() ?? '',
      START_NOTE: json['start_note']?.toString() ?? '',
      START_STATUS: json['start_status']?.toString() ?? '',
      START_ADDRESS: json['start_address']?.toString() ?? '',
      START_LATITUDE: json['start_latitude']?.toString() ?? '',
      START_LONGITUDE: json['start_longitude']?.toString() ?? '',
      START_LOCATION_STATUS: json['start_location_status']?.toString() ?? '',
      START_LOCATION_SUB_STATUS:
          json['start_location_sub_status']?.toString() ?? '',
      END_TIME: json['end_time']?.toString() ?? '',
      END_IMAGE: json['end_image']?.toString() ?? '',
      // Use end_image instead of tmp path (end_image_small)
      END_IMAGE_SMALL: json['end_image']?.toString() ?? '',
      END_NOTE: json['end_note']?.toString() ?? '',
      END_STATUS: json['end_status']?.toString() ?? '',
      ORG_SUB_NAME: json['org_sub_name']?.toString() ?? '',
    );
  }
}

class ListFaq {
  final String ID;
  final String SUBJECT;
  final String DESCRIPTION;
  final String CREATE_DATE;
  final String UPDATE_DATE;

  ListFaq({
    required this.ID,
    required this.SUBJECT,
    required this.DESCRIPTION,
    required this.CREATE_DATE,
    required this.UPDATE_DATE,
  });

  factory ListFaq.fromJson(Map<String, dynamic> json) {
    return ListFaq(
      ID: json['id'],
      SUBJECT: json['subject'],
      DESCRIPTION: json['description'],
      CREATE_DATE: json['create_date'],
      UPDATE_DATE: json['update_date'],
    );
  }
}

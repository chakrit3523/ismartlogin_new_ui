import 'package:ismart_login/src/features/faq/presentation/pages/model/listFaq.dart';

class ListFaqResult {
  final String MSG;
  final bool STATUS;
  final List<ListFaq> RESULT;

  ListFaqResult(
      {required this.MSG, required this.STATUS, required this.RESULT});

  factory ListFaqResult.fromJson(Map<String, dynamic> json) {
    return ListFaqResult(
      MSG: json['msg'],
      STATUS: json['status'],
      RESULT: List.from(json['result'].map((m) => ListFaq.fromJson(m))),
    );
  }
}

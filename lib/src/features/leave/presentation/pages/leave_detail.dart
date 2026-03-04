import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/future/member_manage_future.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/model/itemMemberResultManage.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/style/font_style.dart';

import 'package:ismart_login/system/shared_preferences.dart';
import 'package:ismart_login/system/widht_device.dart';
import 'package:url_launcher/url_launcher.dart';

class LeaveDetailScreen extends StatefulWidget {
  final String id;
  final Function loadListLeave;
  final Function loadData;
  const LeaveDetailScreen({
    Key? key,
    required this.id,
    required this.loadListLeave,
    required this.loadData,
  }) : super(key: key);
  @override
  _LeaveDetailScreenState createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends State<LeaveDetailScreen> {
  List data = [];
  List dataFiles = [];
  List<String> items = <String>['0'];
  List<ItemsMemberResultManage> _itemMember = [];
  List<File> _files = [];
  String cateName = '';
  String totalLeave = '';
  String cate_name = '';
  String subject = '';
  String fullname = '';
  String position = '';
  String leaveDate = '';
  String leaveEnd = '';
  String leaveNum = '';
  String createDate = '';
  String cid = '';
  String leaveStatus = '';
  String recommend = '';
  String uid = '';
  String phone = '';
  String leaveStatusText = '';
  String createBy = '';
  String halfDayPeriod = '';
  String userclass = '';
  String leave_member = '0';
  String sick_leave = '0';
  String personal_leave = '0';
  String other_leave = '0';
  final List<Color> colorCodes = <Color>[
    Color(0xFFFDAB28),
    Color(0xFF30BEE3),
    Color(0xFF305AE3)
  ];
  final List<Color> colorTextCodes = <Color>[
    Color(0xFFFF7700),
    Color(0xFF01BB50),
    Color(0xFFFF0000),
    Color(0xFFA0BAC6),
  ];
  TextStyle styleDetail = TextStyle(
      fontFamily: FontStyles().FontFamily,
      fontSize: 18,
      color: Colors.black,
      height: 1);
  TextStyle styleButton = TextStyle(
      fontFamily: FontStyles().FontFamily,
      fontSize: 20,
      color: Colors.blue,
      height: 1);
  TextStyle styleHeader = TextStyle(
      fontFamily: FontStyles().FontFamily,
      fontSize: 25,
      color: Colors.white,
      height: 2);
  TextStyle styleSubHeader = TextStyle(
      fontFamily: FontStyles().FontFamily,
      fontSize: 20,
      color: Colors.black38,
      height: 1);

  static const Map<String, int> _thaiMonthMap = <String, int>{
    'มค': 1,
    'ม.ค': 1,
    'กพ': 2,
    'ก.พ': 2,
    'มีค': 3,
    'มี.ค': 3,
    'เมย': 4,
    'เม.ย': 4,
    'พค': 5,
    'พ.ค': 5,
    'มิย': 6,
    'มิ.ย': 6,
    'กค': 7,
    'ก.ค': 7,
    'สค': 8,
    'ส.ค': 8,
    'กย': 9,
    'ก.ย': 9,
    'ตค': 10,
    'ต.ค': 10,
    'พย': 11,
    'พ.ย': 11,
    'ธค': 12,
    'ธ.ค': 12,
  };

  static const List<String> _thaiMonthAbbr = <String>[
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];

  DateTime? _parseLeaveDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }

    final ymd = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(value);
    if (ymd != null) {
      return DateTime(
        int.parse(ymd.group(1)!),
        int.parse(ymd.group(2)!),
        int.parse(ymd.group(3)!),
      );
    }

    final dmy = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4})$').firstMatch(value);
    if (dmy != null) {
      int year = int.parse(dmy.group(3)!);
      if (year < 100) {
        year = (2500 + year) - 543;
      } else if (year > 2400) {
        year -= 543;
      }
      return DateTime(
        year,
        int.parse(dmy.group(2)!),
        int.parse(dmy.group(1)!),
      );
    }

    // e.g. "16 ก.พ. 69"
    final thai = RegExp(r'^(\d{1,2})\s+([^\s]+)\s+(\d{2,4})$').firstMatch(
      value.replaceAll('\u00a0', ' '),
    );
    if (thai != null) {
      final day = int.parse(thai.group(1)!);
      var monthKey = thai.group(2)!.trim();
      monthKey = monthKey.replaceAll(' ', '');
      final normalizedMonth = monthKey.replaceAll('.', '');
      final month = _thaiMonthMap[monthKey] ?? _thaiMonthMap[normalizedMonth];
      if (month == null) {
        return null;
      }

      int year = int.parse(thai.group(3)!);
      if (year < 100) {
        year = (2500 + year) - 543;
      } else if (year > 2400) {
        year -= 543;
      }
      return DateTime(year, month, day);
    }

    return null;
  }

  String _normalizeLeaveNum({
    required String apiLeaveNum,
    required String dateFrom,
    required String dateTo,
  }) {
    final directValue = _sanitizeDateValue(apiLeaveNum);
    final parsedDirect = _extractFirstNumber(directValue);
    if (!directValue.contains('วัน')) {
      if (parsedDirect != null && !directValue.contains('ชม')) {
        return '${_formatLeaveAmount(parsedDirect)} วัน';
      }
      return directValue;
    }

    if (parsedDirect == null) {
      return directValue;
    }
    if (parsedDirect % 1 != 0) {
      return '${_formatLeaveAmount(parsedDirect)} วัน';
    }

    final from = _parseLeaveDate(dateFrom);
    final to = _parseLeaveDate(dateTo);
    if (from == null || to == null) {
      return '${_formatLeaveAmount(parsedDirect)} วัน';
    }

    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    final days = end.difference(start).inDays.abs() + 1;

    final apiDays = parsedDirect.toInt();

    if (apiDays != days) {
      return '$days วัน';
    }

    return '${_formatLeaveAmount(parsedDirect)} วัน';
  }

  double? _extractFirstNumber(String raw) {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
    if (match == null) {
      return null;
    }
    return double.tryParse(match.group(1)!);
  }

  String _formatLeaveAmount(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _sanitizeDateValue(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value.toLowerCase() == 'null') {
      return '';
    }
    return value;
  }

  String _stringOrEmpty(dynamic value) {
    if (value == null) {
      return '';
    }
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '';
    }
    return text;
  }

  String _pickFirstNonEmpty(Iterable<dynamic> candidates) {
    for (final candidate in candidates) {
      final value = _stringOrEmpty(candidate);
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  String _formatThaiShortDate(DateTime value) {
    final buddhistYearShort =
        ((value.year + 543) % 100).toString().padLeft(2, '0');
    return '${value.day} ${_thaiMonthAbbr[value.month - 1]} $buddhistYearShort';
  }

  String _deriveLeaveEndFromLeaveNum(String startDateText) {
    final normalizedLeaveNum = _sanitizeDateValue(leaveNum);
    if (normalizedLeaveNum.isEmpty || !normalizedLeaveNum.contains('วัน')) {
      return '';
    }

    final amount = _extractFirstNumber(normalizedLeaveNum);
    final days = amount == null ? null : amount.ceil();
    if (days == null || days <= 1) {
      return '';
    }

    final start = _parseLeaveDate(startDateText);
    if (start == null) {
      return '';
    }

    final end = DateTime(start.year, start.month, start.day)
        .add(Duration(days: days - 1));
    return _formatThaiShortDate(end);
  }

  String _buildLeaveDateRangeText() {
    final start = _sanitizeDateValue(leaveDate);
    final end = _sanitizeDateValue(leaveEnd);

    if (start.isEmpty && end.isEmpty) {
      return '-';
    }
    if (start.isEmpty) {
      return end;
    }
    final effectiveEnd =
        end.isNotEmpty ? end : _deriveLeaveEndFromLeaveNum(start);
    if (effectiveEnd.isEmpty || effectiveEnd == start) {
      if (halfDayPeriod == 'morning') {
        return '$start (ครึ่งวันเช้า)';
      }
      if (halfDayPeriod == 'afternoon') {
        return '$start (ครึ่งวันบ่าย)';
      }
      return start;
    }

    final rangeText = '$start - $effectiveEnd';
    if (halfDayPeriod == 'last_morning') {
      return '$rangeText (วันสุดท้ายครึ่งวันเช้า)';
    }
    return rangeText;
  }

  void initState() {
    onLoadDetailLeaveManage();
    onLoadMemberManage();
    onLoadLeaveSummary();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    widget.loadData();
  }

  showLoaderDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      content: new Row(
        children: [
          CircularProgressIndicator(),
          Container(
            margin: EdgeInsets.only(left: 7),
            child: Text("กำลังโหลด..."),
          ),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  updateStatusLeave(String status) async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
      "id": widget.id,
      "status_leave": status,
    };
    var body = json.encode(map);
    final response = await http.Client().post(
      Uri.parse(Server().postupdateStatusLeave),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    data = json.decode(response.body);
    if (data[0]['status'] == true) {
      Navigator.of(context, rootNavigator: true).pop('dialog');
      onLoadDetailLeaveManage();
      widget.loadListLeave();
    }
    blocSetState(() {});
  }

  updateStatusCancelLeave(String status) async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
      "id": widget.id,
      "status_leave": status,
    };
    var body = json.encode(map);
    final response = await http.Client().post(
      Uri.parse(Server().postupdateCancelStatusLeave),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    data = json.decode(response.body);
    if (data[0]['status'] == true) {
      Navigator.of(context, rootNavigator: true).pop('dialog');
      onLoadDetailLeaveManage();
      widget.loadListLeave();
    }
    blocSetState(() {});
  }

  Future<void> _pickAndUploadMedicalCertificate() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    showLoaderDialog(context);

    try {
      var uri = Uri.parse(Server().uploadLeaveMedicalCertificate);
      var request = http.MultipartRequest('POST', uri);

      request.fields['org_id'] = await SharedCashe.getItemsWay(name: 'org_id');
      request.fields['uid'] = await SharedCashe.getItemsWay(name: 'id');
      request.fields['leave_id'] = widget.id;

      var ext = image.path.split('.').last;
      var file = await http.MultipartFile.fromPath('file[0]', image.path,
          contentType: MediaType('image', ext));
      request.files.add(file);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      Navigator.of(context, rootNavigator: true).pop('dialog');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['msg'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('อัพโหลดใบรับรองแพทย์สำเร็จ'),
                backgroundColor: Colors.green),
          );
          onLoadDetailLeaveManage();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('ไม่สามารถอัพโหลดได้'),
                backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop('dialog');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _launchInBrowser(String url) async {
    final _uri = Uri.parse(url);
    if (await canLaunchUrl(_uri)) {
      await launchUrl(_uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  bool _isImageAttachment(dynamic file) {
    final extension = (file['extension'] ?? '').toString().toLowerCase();
    const imageExtensions = {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'heic',
      'heif',
    };

    if (imageExtensions.contains(extension)) {
      return true;
    }

    final path = (file['path'] ?? '').toString().toLowerCase();
    return imageExtensions.any((ext) => path.endsWith('.$ext'));
  }

  void _showImagePreview(String path, String filename) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.network(
                        path,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image,
                                color: Colors.white70, size: 48),
                            SizedBox(height: 12),
                            Text(
                              'ไม่สามารถโหลดรูปภาพได้',
                              style: GoogleFonts.kanit(
                                  color: Colors.white70, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                ),
                if (filename.isNotEmpty)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Text(
                      filename,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.kanit(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageAttachmentThumbnail(dynamic file) {
    final path = (file['path'] ?? '').toString();
    final filename = (file['filename'] ?? '').toString();

    return InkWell(
      onTap: () => _showImagePreview(path, filename),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Image.network(
                path,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade100,
                  alignment: Alignment.center,
                  child: Icon(Icons.broken_image,
                      color: Colors.grey.shade500, size: 28),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(Icons.image_outlined, size: 14, color: Colors.blue),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      filename,
                      style:
                          GoogleFonts.kanit(fontSize: 13, color: Colors.blue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(dynamic file) {
    final path = (file['path'] ?? '').toString();
    final filename = (file['filename'] ?? '').toString();
    return InkWell(
      onTap: () => _launchInBrowser(path),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.attach_file, size: 16, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                filename,
                style: GoogleFonts.kanit(fontSize: 16, color: Colors.blue),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  onLoadDetailLeaveManage() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
      "id": widget.id,
    };
    print("onLoadDetailLeaveManage : ${map}");
    var body = json.encode(map);
    final response = await http.Client().post(
      Uri.parse(Server().getDetailLeave),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    data = json.decode(response.body);
    // print(data);
    if (data[0]['status'] == true) {
      cateName = data[0]['cateName'].toString();
      halfDayPeriod = data[0]['half_day_period']?.toString() ?? '';
      if (halfDayPeriod == 'morning') {
        cateName += ' (ครึ่งวันเช้า)';
      } else if (halfDayPeriod == 'afternoon') {
        cateName += ' (ครึ่งวันบ่าย)';
      } else if (halfDayPeriod == 'last_morning') {
        cateName += ' (วันสุดท้ายครึ่งวันเช้า)';
      }

      totalLeave = data[0]['totalLeave'].toString();
      cate_name = data[0]['cate_name'].toString();
      cid = data[0]['cid'].toString();
      leaveStatus = data[0]['leaveStatus'].toString();
      recommend = data[0]['recommend'].toString();
      fullname = data[0]['fullname'].toString();
      subject = data[0]['subject'].toString();
      position = data[0]['position'].toString();
      leaveDate = _pickFirstNonEmpty([
        data[0]['leaveDate'],
        data[0]['dateLeave'],
        data[0]['FirstDate'],
        data[0]['first_date'],
      ]);
      leaveEnd = _pickFirstNonEmpty([
        data[0]['leaveEnd'],
        data[0]['LastDate'],
        data[0]['last_date'],
        data[0]['dateEnd'],
        data[0]['date_to'],
      ]);
      leaveNum = _normalizeLeaveNum(
        apiLeaveNum:
            _pickFirstNonEmpty([data[0]['leaveNum'], data[0]['numDate']]),
        dateFrom: leaveDate,
        dateTo: leaveEnd,
      );
      createDate = data[0]['createDate'].toString();
      createBy = data[0]['create_by'].toString();
      phone = data[0]['phone'].toString();
      uid = await SharedCashe.getItemsWay(name: 'id');
      leaveStatusText = data[0]['leaveStatusText'].toString();
      dataFiles = data[0]['files'] ?? [];
    }
    blocSetState(() {});
  }

  Future<void> onLoadLeaveSummary() async {
    final map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
      "status_leave": "",
      "cid": "",
      "month_start": "",
      "year_start": "",
      "month_end": "",
      "year_end": "",
    };
    final body = json.encode(map);
    final response = await http.Client().post(
      Uri.parse(Server().getListLeave),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    final leaveData = json.decode(response.body);

    if (leaveData is List && leaveData.isNotEmpty) {
      sick_leave = leaveData[0]['sick']?.toString() ?? '0';
      personal_leave = leaveData[0]['leave']?.toString() ?? '0';
      other_leave = leaveData[0]['other']?.toString() ?? '0';
      if (mounted) {
        blocSetState(() {});
      }
    }
  }

  Future<bool> onLoadMemberManage() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
    };
    await MemberManageFuture().apiGetMemberManageList(map).then((onValue) {
      blocSetState(() {
        if (onValue[0].STATUS) {
          _itemMember = onValue[0].RESULT;
          userclass = _itemMember[0].MEMBER_TYPE.toString();
          leave_member = _itemMember[0].LEAVE_MEMBER.toString();
        }
      });
    });
    blocSetState(() {});
    return true;
  }

  alert_confirm(BuildContext context, String text, String status) async {
    return showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          contentPadding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
          content: Container(
            width: WidhtDevice().widht(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      EdgeInsets.only(top: 30, bottom: 30, left: 3, right: 3),
                  alignment: Alignment.center,
                  child: Text(
                    text,
                    style: TextStyle(
                        fontFamily: FontStyles().FontFamily, fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20.0),
                                bottomRight: Radius.circular(20.0),
                              ),
                            ),
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              'ยกเลิก',
                              style: TextStyle(
                                  fontFamily: FontStyles().FontFamily,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            showLoaderDialog(context);
                            updateStatusLeave(status);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF00B9FF),
                              borderRadius: BorderRadius.only(
                                // bottomLeft: Radius.circular(20.0),
                                bottomRight: Radius.circular(20.0),
                              ),
                            ),
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              'ยืนยัน',
                              style: TextStyle(
                                  fontFamily: FontStyles().FontFamily,
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  alert_cancel_confirm(BuildContext context, String text, String status) async {
    return showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          contentPadding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
          content: Container(
            width: WidhtDevice().widht(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      EdgeInsets.only(top: 30, bottom: 30, left: 3, right: 3),
                  alignment: Alignment.center,
                  child: Text(
                    text,
                    style: TextStyle(
                        fontFamily: FontStyles().FontFamily, fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20.0),
                                bottomRight: Radius.circular(20.0),
                              ),
                            ),
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              'ยกเลิก',
                              style: TextStyle(
                                  fontFamily: FontStyles().FontFamily,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            showLoaderDialog(context);
                            updateStatusCancelLeave(status);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF00B9FF),
                              borderRadius: BorderRadius.only(
                                // bottomLeft: Radius.circular(20.0),
                                bottomRight: Radius.circular(20.0),
                              ),
                            ),
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              'ยืนยัน',
                              style: TextStyle(
                                  fontFamily: FontStyles().FontFamily,
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String days, Color color) {
    return Container(
      width: 100, // Fixed width for each card
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.kanit(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 4),
          Text(
            days,
            style: GoogleFonts.kanit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            "วัน",
            style: GoogleFonts.kanit(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageFiles =
        dataFiles.where((file) => _isImageAttachment(file)).toList();
    final otherFiles =
        dataFiles.where((file) => !_isImageAttachment(file)).toList();

    return Scaffold(
      backgroundColor: Color(0xFF21CCD4), // Cyan background for the scaffold
      appBar: AppBar(
        title: Text(
          "อนุมัติการลา",
          style: GoogleFonts.kanit(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Leave Detail Card
                  if (data.length > 0)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3), // changes position of shadow
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          // Card Header
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Color(0xFFE1DDFE), // Light purple
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Text(
                              cateName,
                              style: GoogleFonts.kanit(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // Card Body
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildDetailRow("ชื่อ – สกุล", fullname),
                                _buildDetailRow("ตำแหน่ง", position),
                                _buildDetailRow(
                                    "ลาวันที่", _buildLeaveDateRangeText()),
                                _buildDetailRow("เนื่องจาก", subject),
                                _buildDetailRow("รวม", leaveNum),
                                _buildDetailRow("ส่งใบลา", createDate),
                                _buildDetailRow("เบอร์ที่ติดต่อได้", phone),
                                _buildDetailRow("สถานะคำขอลา", leaveStatusText,
                                    color: Color(0xFFFF7700)),
                                if (dataFiles.length > 0) ...[
                                  Divider(height: 20),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "เอกสารแนบ",
                                      style: GoogleFonts.kanit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  if (imageFiles.isNotEmpty)
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: imageFiles.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 8,
                                        crossAxisSpacing: 8,
                                        childAspectRatio: 0.95,
                                      ),
                                      itemBuilder: (context, index) =>
                                          _buildImageAttachmentThumbnail(
                                              imageFiles[index]),
                                    ),
                                  if (otherFiles.isNotEmpty) ...[
                                    if (imageFiles.isNotEmpty)
                                      SizedBox(height: 8),
                                    ...otherFiles
                                        .map<Widget>((file) =>
                                            _buildAttachmentItem(file))
                                        .toList(),
                                  ],
                                ],
                                // Show upload button for sick leave (cid == "2") owned by user
                                if (cid == "2" &&
                                    createBy == uid &&
                                    (leaveStatus == "1" ||
                                        leaveStatus == "2")) ...[
                                  Divider(height: 20),
                                  InkWell(
                                    onTap: _pickAndUploadMedicalCertificate,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.green.shade300),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_photo_alternate,
                                              color: Colors.green, size: 24),
                                          SizedBox(width: 8),
                                          Text(
                                            'แนบใบรับรองแพทย์',
                                            style: GoogleFonts.kanit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 24),

                  // Leave Statistics
                  Text(
                    "สถิติการลา",
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: _buildStatCard(
                              "ลาป่วย", sick_leave, Color(0xFFFDAB28))),
                      SizedBox(width: 8),
                      Expanded(
                          child: _buildStatCard(
                              "ลากิจ", personal_leave, Color(0xFF7F6CF5))),
                      SizedBox(width: 8),
                      Expanded(
                          child: _buildStatCard(
                              "ลาอื่นๆ", other_leave, Color(0xFF90D064))),
                    ],
                  ),

                  SizedBox(height: 32),

                  // Action Buttons
                  if (data.length > 0) _buildActionButtons(context),

                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.kanit(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: GoogleFonts.kanit(
                fontSize: 16,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if ((createBy == uid) &&
        (leaveStatus != "3") &&
        (leaveStatus != "4") &&
        (leaveStatus != "2")) {
      // Cancel
      return Center(
          child: _buildButton(
              context,
              "ยกเลิก",
              Color(0xFFBBBBBB),
              Colors.white,
              () => alert_confirm(
                  context, "คุณต้องการ “ยกเลิก” การลาหรือไม่", "4")));
    } else if ((createBy == uid) && (leaveStatus == "2")) {
      // Cancel Approved
      return Center(
          child: _buildButton(
              context,
              "ยกเลิก",
              Color(0xFFBBBBBB),
              Colors.white,
              () => alert_confirm(
                  context, "คุณต้องการ “ยกเลิก” การลาหรือไม่", "4")));
    } else if ((leaveStatus == "4") &&
        (recommend == "1") &&
        (createBy != uid)) {
      // Cancel Request Approval
      return Row(
        children: [
          Expanded(
              child: _buildButton(
                  context,
                  "ไม่อนุมัติ",
                  Color(0xFFBBBBBB),
                  Colors.white,
                  () => alert_cancel_confirm(context,
                      "คุณต้องการ “ไม่อนุมัติ” ยกเลิกการลาหรือไม่", "2"))),
          SizedBox(width: 16),
          Expanded(
              child: _buildGradientButton(
                  context,
                  "อนุมัติ",
                  () => alert_cancel_confirm(context,
                      "คุณต้องการ “อนุมัติ” ยกเลิกการลาหรือไม่", "1"))),
        ],
      );
    } else if ((createBy != uid) &&
        (leaveStatus != "3") &&
        (leaveStatus != "2") &&
        (leaveStatus != "4") &&
        (userclass == "admin" || leave_member == "1")) {
      // Approval Buttons
      return Row(
        children: [
          Expanded(
              child: _buildGradientButton(
                  context,
                  "อนุมัติ",
                  () => alert_confirm(
                      context,
                      "คุณต้องการ “อนุมัติ” การลาหรือไม่",
                      "2"))), // In UI image, Approve is left, Wait. No.
          // Image: Approve (Blue) LEFT? No, usually OK is Right.
          // The image shows: [ Approve (Blue) ] [ Reject (Grey) ].
          // Wait, let me check the image again.
          // The image has Blue (Approve) on Left, Grey (Reject) on Right?
          // Let me check image... "อนุมัติ" (Blue) is Left. "ไม่อนุมัติ" (Grey) is Right.
          // This is a bit unusual (usually positive action is right), but I will follow the image.
          // Actually, let's look closer at the image.
          // Image: [ Cyan Button (Anumati) ]  [ Grey Button (Mai Anumati) ]
          // So Cyan is Left, Grey is Right.
          SizedBox(width: 16),
          Expanded(
              child: _buildButton(
                  context,
                  "ไม่อนุมัติ",
                  Color(0xFFBBBBBB),
                  Colors.white,
                  () => alert_confirm(
                      context, "คุณต้องการ “ไม่อนุมัติ” การลาหรือไม่", "3"))),
        ],
      );
    }
    return Container();
  }

  Widget _buildButton(BuildContext context, String text, Color bgColor,
      Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: GoogleFonts.kanit(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton(
      BuildContext context, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF21CCD4), Color(0xFF0680F7)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: GoogleFonts.kanit(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

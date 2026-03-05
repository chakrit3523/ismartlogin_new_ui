// ignore_for_file: unnecessary_null_comparison

import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';

import 'package:ismart_login/server/server.dart';

import 'package:ismart_login/system/shared_preferences.dart';

import 'leave_detail.dart';

class LeaveHistoryScreen extends StatefulWidget {
  @override
  _LeaveHistoryScreenState createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
  List data = [];
  List statusData = [];
  List typesData = [];
  String sick = '0';
  String leave = '0';
  String other = '0';
  String len = '0';

  String dropdownValueStartMonth = "เลือกเดือน";
  String dropdownValueStartYear = "เลือกปี";
  String dropdownValueEndMonth = "เลือกเดือน";
  String dropdownValueEndYear = "เลือกปี";

  void initState() {
    onLoadListLeaveManage();
    super.initState();
  }

  onLoadListLeaveManage() async {
    String statusLeave = '';
    String typesLeave = '';
    if (statusData != null && statusData.length > 0) {
      statusLeave = statusData.join(',');
    }
    if (typesData != null && typesData.length > 0) {
      typesLeave = typesData.join(',');
    }
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
      "status_leave": statusLeave,
      "cid": typesLeave,
      "month_start": dropdownValueStartMonth != "เลือกเดือน"
          ? dropdownValueStartMonth
          : "",
      "year_start":
          dropdownValueStartYear != "เลือกปี" ? dropdownValueStartYear : "",
      "month_end":
          dropdownValueEndMonth != "เลือกเดือน" ? dropdownValueEndMonth : "",
      "year_end": dropdownValueEndYear != "เลือกปี" ? dropdownValueEndYear : "",
    };
    var body = json.encode(map);
    final response = await http.Client().post(
      Uri.parse(Server().getListHistoryLeave),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    data = json.decode(response.body);
    // print(data);
    if (data[0]['status'] == true) {
      len = data[0]['result'].length.toString();
      sick = data[0]['sick'].toString();
      leave = data[0]['leave'].toString();
      other = data[0]['other'].toString();
    } else {
      len = data[0]['result'].length.toString();
    }
    blocSetState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List rs = [];
    if (data.length > 0 && data[0]['result'] != null) {
      rs = data[0]['result'];
    }

    return Scaffold(
      backgroundColor: Color(0xFF21CCD4),
      appBar: AppBar(
        title: Text(
          'ประวัติการลา',
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
        margin: EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 20),
            // Statistics Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard(
                      "ลาป่วย", sick, Color(0xFFFFE0B2), Color(0xFF000000)),
                  _buildStatCard(
                      "ลากิจ", leave, Color(0xFFE1BEE7), Color(0xFF000000)),
                  _buildStatCard(
                      "ลาอื่นๆ", other, Color(0xFFC8E6C9), Color(0xFF000000)),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Leave History List
            Expanded(
              child: rs.length > 0
                  ? ListView.builder(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      itemCount: rs.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryItem(rs[index]);
                      },
                    )
                  : Center(
                      child: Text(
                        "- ไม่มีข้อมูล -",
                        style: GoogleFonts.kanit(
                          color: Colors.grey,
                          fontSize: 18,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String count, Color bgColor, Color textColor) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48) / 3,
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              title,
              style: GoogleFonts.kanit(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.kanit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map item) {
    String typeName = item['cate_name'] ?? '';
    String dateRange = item['dateLeave'] ?? '';
    String status = item['status_leave_text'] ?? '';
    String statusId = item['status_leave'] ?? '1';

    Color badgeColor = _getTypeColor(typeName);
    Color statusColor = _getStatusColor(statusId);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeaveDetailScreen(
              id: item['id'].toString(),
              loadListLeave: onLoadListLeaveManage,
              loadData: onLoadListLeaveManage,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              padding: EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                typeName,
                style: GoogleFonts.kanit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                dateRange,
                style: GoogleFonts.kanit(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              status,
              style: GoogleFonts.kanit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[300])
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    if (type.contains("ป่วย")) return Color(0xFFFFE0B2); // Orange - Sick
    if (type.contains("กิจ")) return Color(0xFFE1BEE7); // Purple - Personal
    return Color(0xFFC8E6C9); // Green - Other
  }

  Color _getStatusColor(String statusId) {
    switch (statusId) {
      case '1':
        return Color(0xFFFF9800); // Pending (Orange)
      case '2':
        return Color(0xFF4CAF50); // Approved (Green)
      case '3':
        return Color(0xFFF44336); // Rejected (Red)
      case '9':
        return Colors.grey; // Cancel (Grey)
      default:
        return Colors.grey;
    }
  }
}

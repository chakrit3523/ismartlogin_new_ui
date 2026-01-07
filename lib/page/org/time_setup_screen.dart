import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:ismart_login/page/managements/future/org_manage_future.dart';
import 'package:ismart_login/page/managements/future/time_manage_future.dart';
import 'package:ismart_login/system/shared_preferences.dart';
import 'package:ismart_login/page/splashscreen/splashscreen_screen.dart';

class TimeSetupScreen extends StatefulWidget {
  final String orgName;
  final double latitude;
  final double longitude;
  final String address;
  final int radius;
  final Function(double, double, String, int)? onCreateOrg;

  const TimeSetupScreen({
    Key? key,
    required this.orgName,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.radius,
    this.onCreateOrg,
  }) : super(key: key);

  @override
  State<TimeSetupScreen> createState() => _TimeSetupScreenState();
}

class _TimeSetupScreenState extends State<TimeSetupScreen> {
  // Days of the week
  final List<String> _dayNames = [
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์'
  ];

  // Default time settings
  final List<Map<String, dynamic>> _daySettings = [];

  @override
  void initState() {
    super.initState();
    // Initialize day settings with defaults
    for (int i = 0; i < 7; i++) {
      _daySettings.add({
        'enabled': i < 5, // Mon-Fri enabled by default
        'checkIn': '8.30 น.',
        'checkOut': '17.30 น.',
      });
    }
  }

  String _formatTime(String timeStr) {
    // "8.30 น." -> "08:30"
    String t = timeStr.replaceAll(' น.', '');
    List<String> parts = t.split('.');
    String h = parts[0].padLeft(2, '0');
    String m = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
    return "$h:$m";
  }

  Future<void> _onStartPressed() async {
    // If callback provided, use it (for backward compatibility)
    if (widget.onCreateOrg != null) {
      widget.onCreateOrg!(
        widget.latitude,
        widget.longitude,
        widget.address,
        widget.radius,
      );
      return;
    }

    // Otherwise, create org directly
    EasyLoading.show(status: 'กำลังสร้างทีม/องค์กร...');

    try {
      String uid = await SharedCashe.getItemsWay(name: 'id') ?? '';
      print(uid);
      Map<String, dynamic> orgData = {
        "subject": widget.orgName,
        "type": "insert",
        "id": "0",
        "uid": uid,
        "lat": widget.latitude.toString(),
        "lng": widget.longitude.toString(),
        "address": widget.address,
        "radius": widget.radius.toString(),
      };

      print("Creating org with data: $orgData");

      await OrgManageFuture()
          .apiPostOrgManageList(orgData)
          .then((onValue) async {
        print("API Response: onValue = $onValue");

        if (onValue.isNotEmpty && onValue[0].STATUS == true) {
          // Org created successfully. Now save time schedule if ID is available.
          try {
            String? newOrgId = onValue[0].ID;

            if (newOrgId != null && newOrgId.isNotEmpty) {
              // Build Schedule JSON
              List<Map<String, dynamic>> scheduleList = [];
              for (int i = 0; i < 7; i++) {
                if (_daySettings[i]['enabled']) {
                  scheduleList.add({
                    'day': i,
                    'time_start': _formatTime(_daySettings[i]['checkIn']),
                    'time_end': _formatTime(_daySettings[i]['checkOut']),
                  });
                }
              }

              String scheduleJson = jsonEncode(scheduleList);

              // Get Current User ID
              String? uid = await SharedCashe.getItemsWay(name: 'id');

              // Call Time API
              await TimeManageFuture().apiPostTimeManageList({
                "subject": "เวลาทำการ",
                "org_id": newOrgId,
                "description": scheduleJson,
                "status": "1",
                "type": "insert",
                "id": "0",
                "uid": uid // Send UID to backend for auto-assignment
              });
            }
          } catch (e) {
            print("Error saving time schedule: $e");
          }

          EasyLoading.showSuccess('สร้างทีม/องค์กรสำเร็จ');

          // Restart app by navigating to Splash Screen and removing all previous routes
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => SplashscreenScreen()),
            (Route<dynamic> route) => false,
          );
        } else {
          EasyLoading.showError(onValue.isNotEmpty
              ? onValue[0].MSG
              : 'ไม่สามารถสร้างทีม/องค์กรได้');
        }
      });
    } catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด: $e');
      print("Error creating organization: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4FC3F7),
                Color(0xFF29B6F6),
                Color(0xFF03A9F4),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          'ตั้งเวลาการเข้าออกงาน',
                          style: GoogleFonts.kanit(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 10),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Table header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 15),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(
                                  'วัน',
                                  style: GoogleFonts.kanit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF03A9F4),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 70,
                                child: Text(
                                  'เข้างาน',
                                  style: GoogleFonts.kanit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF03A9F4),
                                  ),
                                ),
                              ),
                              SizedBox(width: 15),
                              SizedBox(
                                width: 70,
                                child: Text(
                                  'ออกงาน',
                                  style: GoogleFonts.kanit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF03A9F4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Day rows
                        Expanded(
                          child: ListView.builder(
                            itemCount: 7,
                            itemBuilder: (context, index) {
                              return _buildDayRow(index);
                            },
                          ),
                        ),

                        // Start button
                        SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF4FC3F7),
                                Color(0xFF03A9F4),
                              ],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: _onStartPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              'เริ่มต้นใช้งาน',
                              style: GoogleFonts.kanit(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show time picker dialog
  Future<void> _showTimePicker(int dayIndex, String timeType) async {
    final day = _daySettings[dayIndex];
    final currentTimeStr = day[timeType] as String;

    // Parse current time (format: "8.30 น.")
    final timeParts = currentTimeStr.replaceAll(' น.', '').split('.');
    final hour = int.tryParse(timeParts[0]) ?? 8;
    final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF03A9F4),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final formattedTime =
            '${picked.hour}.${picked.minute.toString().padLeft(2, '0')} น.';
        _daySettings[dayIndex][timeType] = formattedTime;
      });
    }
  }

  Widget _buildDayRow(int index) {
    final day = _daySettings[index];
    final isEnabled = day['enabled'] as bool;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              _dayNames[index],
              style: GoogleFonts.kanit(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
          if (isEnabled) ...[
            GestureDetector(
              onTap: () => _showTimePicker(index, 'checkIn'),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  day['checkIn'],
                  style: GoogleFonts.kanit(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            Text(' - ', style: TextStyle(color: Colors.black54)),
            GestureDetector(
              onTap: () => _showTimePicker(index, 'checkOut'),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  day['checkOut'],
                  style: GoogleFonts.kanit(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ] else ...[
            Text(
              'วันหยุด',
              style: GoogleFonts.kanit(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
          Spacer(),
          Switch(
            value: isEnabled,
            onChanged: (value) {
              setState(() {
                _daySettings[index]['enabled'] = value;
              });
            },
            activeThumbColor: Color(0xFF4CAF50),
            activeTrackColor: Color(0xFF4CAF50).withValues(alpha: 0.5),
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }
}

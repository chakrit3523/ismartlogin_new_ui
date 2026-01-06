import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:ismart_login/page/managements/future/time_manage_future.dart';
import 'package:ismart_login/page/managements/model/itemTimeResultDayManage.dart';
import 'package:ismart_login/system/shared_preferences.dart';

class OrgTimeDetailManage extends StatefulWidget {
  final String id;
  final String org_id;
  final String type;
  final Function? updateLoadTime;

  OrgTimeDetailManage({
    super.key,
    required this.id,
    required this.org_id,
    required this.type,
    this.updateLoadTime,
  });

  @override
  _OrgTimeDetailManageState createState() => _OrgTimeDetailManageState();
}

class _OrgTimeDetailManageState extends State<OrgTimeDetailManage> {
  final TextEditingController _inputSubject = TextEditingController();

  final List<String> _dayNames = [
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์'
  ];

  // Store UI state: { enabled: bool, checkIn: "8.30 น.", checkOut: "17.30 น." }
  List<Map<String, dynamic>> _daySettings = [];

  @override
  void initState() {
    super.initState();
    _initializeDefaultSettings();

    if (widget.type == 'update') {
      onLoadGetTime();
    }
  }

  void _initializeDefaultSettings() {
    _daySettings = [];
    for (int i = 0; i < 7; i++) {
      _daySettings.add({
        'enabled': i < 5, // Default Mon-Fri
        'checkIn': '8.30 น.',
        'checkOut': '17.30 น.',
      });
    }
  }

  /// Convert API time ("08:30:00") to UI format ("8.30 น.")
  String _apiToUiTime(String apiTime) {
    try {
      List<String> parts = apiTime.split(':');
      int h = int.parse(parts[0]);
      int m = int.parse(parts[1]);
      return '$h.${m.toString().padLeft(2, '0')} น.';
    } catch (e) {
      return apiTime; // Fallback
    }
  }

  /// Convert UI format ("8.30 น.") to API time ("08:30:00")
  String _uiToApiTime(String uiTime) {
    try {
      String t = uiTime.replaceAll(' น.', '');
      List<String> parts = t.split('.');
      String h = parts[0].padLeft(2, '0');
      String m = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
      return "$h:$m:00";
    } catch (e) {
      return "00:00:00";
    }
  }

  Future<void> onLoadGetTime() async {
    EasyLoading.show(status: 'กำลังโหลด...');
    Map map = {"org_id": widget.org_id, "id": widget.id};

    await TimeManageFuture().apiGetTimeManageList(map).then((onValue) {
      if (onValue.isNotEmpty && onValue[0].STATUS == true) {
        var item = onValue[0].RESULT[0];
        _inputSubject.text = item.SUBJECT;

        List<ItemsTimeResultDayManage> days = List.from(json
            .decode(item.DESCRIPTION)
            .map((m) => ItemsTimeResultDayManage.fromJson(m)));

        setState(() {
          // Reset all to disabled first
          for (var day in _daySettings) {
            day['enabled'] = false;
          }

          // Enable days found in API response
          for (var d in days) {
            if (d.DAY >= 0 && d.DAY < 7) {
              _daySettings[d.DAY]['enabled'] = true;
              _daySettings[d.DAY]['checkIn'] = _apiToUiTime(d.TIME_START);
              _daySettings[d.DAY]['checkOut'] = _apiToUiTime(d.TIME_END);
            }
          }
        });
      }
    });
    EasyLoading.dismiss();
  }

  Future<void> _saveData() async {
    if (_inputSubject.text.isEmpty) {
      EasyLoading.showError('กรุณาระบุชื่อเวลา');
      return;
    }

    EasyLoading.show(status: 'กำลังบันทึก...');

    List<Map<String, dynamic>> scheduleList = [];
    for (int i = 0; i < 7; i++) {
      if (_daySettings[i]['enabled']) {
        scheduleList.add({
          "day": i,
          "time_start": _uiToApiTime(_daySettings[i]['checkIn']),
          "time_end": _uiToApiTime(_daySettings[i]['checkOut'])
        });
      }
    }

    if (scheduleList.isEmpty) {
      EasyLoading.showError('กรุณาเลือกวันทำงานอย่างน้อย 1 วัน');
      return;
    }

    Map map = {
      "subject": _inputSubject.text,
      "org_id": widget.org_id != ''
          ? widget.org_id
          : await SharedCashe.getItemsWay(name: 'org_id'),
      "description": json.encode(scheduleList),
      "status": "1",
      "id": widget.id,
      "type": widget.type,
      // "uid": uid // API might need UID for logs, but old code didn't send it here for update?
      // Checking old code: old code didn't send UID in _setDetailDayToJson.
      // It sent subject, org_id, description, status, id, type.
    };

    await TimeManageFuture().apiPostTimeManageList(map).then((onValue) {
      if (onValue.isNotEmpty && onValue[0].STATUS == true) {
        EasyLoading.showSuccess('บันทึกสำเร็จ');
        if (widget.updateLoadTime != null) {
          widget.updateLoadTime!();
        }
        Navigator.pop(context, true);
      } else {
        EasyLoading.showError(
            onValue.isNotEmpty ? onValue[0].MSG : 'บันทึกไม่สำเร็จ');
      }
    });
  }

  Future<void> _showTimePicker(int dayIndex, String timeType) async {
    final day = _daySettings[dayIndex];
    final currentTimeStr = day[timeType] as String;

    // Parse "8.30 น." -> Hour 8, Minute 30
    final t = currentTimeStr.replaceAll(' น.', '');
    final parts = t.split('.');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF21CCD4), Color(0xFF0663F7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    UnconstrainedBox(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.type == 'insert'
                            ? 'เพิ่มตารางเวลา'
                            : 'แก้ไขตารางเวลา',
                        style: GoogleFonts.kanit(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Save Button (Icon style or Text)
                    // Let's use a nice Text button or Icon
                  ],
                ),
              ),

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
                      // Subject Input
                      TextFormField(
                        controller: _inputSubject,
                        style: GoogleFonts.kanit(fontSize: 18),
                        decoration: InputDecoration(
                          labelText: 'ชื่อเวลา (เช่น เวลาทำการ, กะเช้า)',
                          labelStyle:
                              GoogleFonts.kanit(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.access_time_filled,
                              color: Color(0xFF03A9F4)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Color(0xFF03A9F4)),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Table Header
                      Row(
                        children: [
                          SizedBox(
                              width: 80,
                              child: Text('วัน',
                                  style: GoogleFonts.kanit(
                                      color: Color(0xFF03A9F4),
                                      fontWeight: FontWeight.bold))),
                          Expanded(
                              child: Text('เข้างาน - ออกงาน',
                                  style: GoogleFonts.kanit(
                                      color: Color(0xFF03A9F4),
                                      fontWeight: FontWeight.bold))),
                          SizedBox(
                              width: 50,
                              child: Text(
                                'สถานะ',
                                style: GoogleFonts.kanit(
                                    color: Color(0xFF03A9F4),
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.end,
                              )),
                        ],
                      ),
                      Divider(),

                      // Days List
                      Expanded(
                        child: _daySettings.isEmpty
                            ? Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                itemCount: 7,
                                itemBuilder: (context, index) =>
                                    _buildDayRow(index),
                              ),
                      ),

                      SizedBox(height: 20),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF4FC3F7), Color(0xFF03A9F4)],
                              ),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                'บันทึก',
                                style: GoogleFonts.kanit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayRow(int index) {
    final day = _daySettings[index];
    final isEnabled = day['enabled'] as bool;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              _dayNames[index],
              style: GoogleFonts.kanit(fontSize: 16),
            ),
          ),
          if (isEnabled) ...[
            Expanded(
              child: Row(
                children: [
                  InkWell(
                    onTap: () => _showTimePicker(index, 'checkIn'),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        day['checkIn'],
                        style: GoogleFonts.kanit(color: Colors.blue[800]),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child:
                        Text('-', style: GoogleFonts.kanit(color: Colors.grey)),
                  ),
                  InkWell(
                    onTap: () => _showTimePicker(index, 'checkOut'),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        day['checkOut'],
                        style: GoogleFonts.kanit(color: Colors.orange[900]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Expanded(
              child: Text('วันหยุด',
                  style: GoogleFonts.kanit(
                      color: Colors.grey[400], fontStyle: FontStyle.italic)),
            ),
          ],
          Switch(
            value: isEnabled,
            onChanged: (val) {
              setState(() {
                _daySettings[index]['enabled'] = val;
              });
            },
            activeColor: Color(0xFF4CAF50),
            activeTrackColor: Color(0xFF4CAF50).withOpacity(0.4),
            inactiveThumbColor: Colors.grey[300],
            inactiveTrackColor: Colors.grey[200],
          ),
        ],
      ),
    );
  }
}

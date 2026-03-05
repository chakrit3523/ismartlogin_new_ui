import 'dart:async';

import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ismart_login/src/features/front/presentation/pages/front_count_absence_screen.dart';
import 'package:ismart_login/src/features/front/presentation/pages/front_count_late_screen.dart';
import 'package:ismart_login/src/features/front/presentation/pages/front_count_ontime_screen.dart';
import 'package:ismart_login/src/features/front/presentation/pages/front_count_outside_screen.dart';
import 'package:ismart_login/src/features/front/presentation/pages/future/summary_future.dart';
import 'package:ismart_login/src/features/front/presentation/pages/model/sumaryToDay.dart';
import 'package:ismart_login/src/features/front/presentation/pages/model/sumaryToDay_absence.dart';
import 'package:ismart_login/src/features/front/presentation/pages/model/sumaryToDay_late.dart';
import 'package:ismart_login/src/features/front/presentation/pages/model/sumaryToDay_ontime.dart';
import 'package:ismart_login/src/features/front/presentation/pages/model/sumaryToDay_outside.dart';
import 'package:ismart_login/system/shared_preferences.dart';

import 'front_count_ot_screen.dart';
import 'model/sumaryToDay_ot.dart';

class FrontCountWidget extends StatefulWidget {
  final String? scheduledEndTime;
  const FrontCountWidget({super.key, this.scheduledEndTime});
  @override
  _FrontCountWidgetState createState() => _FrontCountWidgetState();
}

class _FrontCountWidgetState extends State<FrontCountWidget> {
  var newFormat = DateFormat("yyyy-MM-dd");

  @override
  void initState() {
    _loadData();
    super.initState();
  }

  _loadData() async {
    Map _map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "create_date": newFormat.format(DateTime.now())
    };
    onLoadGetSummaryToDay(_map);
  }

  List<ItemsSummaryToDay> _result = [];
  List<ItemsSummaryToDay_Ontime> _result_ontime = [];
  List<ItemsSummaryToDay_Late> _result_late = [];
  List<ItemsSummaryToDay_Absence> _result_absence = [];
  List<ItemsSummaryToDay_Outside> _result_outside = [];
  List<ItemsSummaryToDay_OT> _result_ot = [];

  Future<bool> onLoadGetSummaryToDay(Map map) async {
    await SummaryFuture().apiGetSummaryToDay(map).then((onValue) {
      _result = onValue;
      if (_result.isNotEmpty) {
        blocSetState(() {
          _result_ontime = _result[0].ONTIME;
          _result_late = _result[0].LATE;
          _result_absence = _result[0].ABSENCE;
          _result_outside = _result[0].OUTSIDE;
          _result_ot = _result[0].OT;
        });
      }
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniStat(
            count: _result_absence.length.toString(),
            label: 'ยังไม่ลงเวลา',
            color: Color(0xFFFF6B6B),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FrontCountAbsenceScreen(
                    items: _result_absence,
                  ),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildMiniStat(
            count: _result_ontime.length.toString(),
            label: 'ทันเวลา',
            color: Color(0xFF51CF66),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FrontCountOntimeScreen(
                    items: _result_ontime,
                    scheduledEndTime: widget.scheduledEndTime,
                  ),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildMiniStat(
            count: _result_late.length.toString(),
            label: 'สาย',
            color: Color(0xFFFF9800),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FrontCountLateScreen(
                    items: _result_late,
                    scheduledEndTime: widget.scheduledEndTime,
                  ),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildMiniStat(
            count: _result_outside.length.toString(),
            label: 'นอกสถานที่',
            color: Color(0xFF9C27B0),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FrontCountOutsideScreen(
                    items: _result_outside,
                    scheduledEndTime: widget.scheduledEndTime,
                  ),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildMiniStat(
            count: _result_ot.length.toString(),
            label: 'OT',
            color: Color(0xFF673AB7),
            onTap: () {
              if (_result_ot.length > 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FrontCountOtScreen(
                      items: _result_ot,
                      scheduledEndTime: widget.scheduledEndTime,
                    ),
                  ),
                );
              }
            },
          ),
          _buildDivider(),
          _buildMiniStat(
            count: '0',
            label: 'ลา',
            color: Color(0xFF64B5F6),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey[300],
    );
  }

  Widget _buildMiniStat({
    required String count,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                count,
                style: GoogleFonts.kanit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1,
                ),
              ),
              SizedBox(width: 2),
              Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(
                  'คน',
                  style: GoogleFonts.kanit(
                    fontSize: 10,
                    color: Colors.grey[600],
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          Container(
            height: 2,
            width: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.kanit(
              fontSize: 9,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

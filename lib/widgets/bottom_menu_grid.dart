import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:ismart_login/page/outside/outside_screen.dart';
import 'package:ismart_login/style/font_style.dart';

class BottomMenuGrid extends StatelessWidget {
  final String uid;
  final double lat;
  final double long;
  final String timeId;

  const BottomMenuGrid({
    Key? key,
    required this.uid,
    required this.lat,
    required this.long,
    this.timeId = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMenuIcon(
              context, 'assets/images/other/workout.png', 'ทำงาน\nนอกสถานที่',
              onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OutsideScreen(
                  uid: uid,
                  lat: lat,
                  long: long,
                ),
              ),
            );
          }),
          _buildMenuIcon(
              context, 'assets/images/other/timeout.png', 'ทำงาน\nล่วงเวลา',
              onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OutsideScreen(
                  uid: uid,
                  lat: lat,
                  long: long,
                  isOvertime: true,
                  timeId: timeId,
                ),
              ),
            );
          }),
          _buildMenuIcon(
              context, 'assets/images/other/holiday.png', 'วันหยุด\nประจำปี',
              onTap: () {
            EasyLoading.showInfo('ยังไม่พร้อมใช้งาน');
          }),
          _buildMenuIcon(
              context, 'assets/images/other/Flat@2x.png', 'ระเบียบ\nบริษัท',
              onTap: () {
            EasyLoading.showInfo('ยังไม่พร้อมใช้งาน');
          }),
        ],
      ),
    );
  }

  Widget _buildMenuIcon(BuildContext context, String assetPath, String title,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 55,
            height: 55,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(assetPath),
          ),
          SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  color: Color(0xFF424242),
                  fontFamily: FontStyles().FontFamily))
        ],
      ),
    );
  }
}

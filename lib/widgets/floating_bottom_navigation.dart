import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class FloatingBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Standard opacity
            blurRadius: 20,
            spreadRadius: 5,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 65,
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMaterialNavItem(
                    icon: FontAwesomeIcons.envelope,
                    label: 'ลา',
                    index: 0,
                  ),
                  _buildMaterialNavItem(
                    icon: FontAwesomeIcons.user,
                    label: 'โปรไฟล์',
                    index: 3,
                  ),
                ],
              ),
              // Center - space for FAB
              SizedBox(width: 60),
              // Right Side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMaterialNavItem(
                    icon: FontAwesomeIcons.history,
                    label: 'ประวัติ',
                    index: 2,
                  ),
                  _buildMaterialNavItem(
                    icon: FontAwesomeIcons.thLarge,
                    label: 'เมนู',
                    index: 4,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    bool isSelected = currentIndex == index;
    return MaterialButton(
      minWidth: 40,
      onPressed: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Color(0xFF4EA9FB) : Colors.grey,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.kanit(
              textStyle: TextStyle(
                color: isSelected ? Color(0xFF4EA9FB) : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingClockFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const FloatingClockFAB({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Color(0xFF21CCD4), // Light Blue
            Color(0xFF0663F7), // Deep Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        onPressed: onPressed,
        child: Image.asset(
          'assets/images/other/clock-plus.png',
          width: 32,
          height: 32,
          color: Colors.white,
        ),
      ),
    );
  }
}

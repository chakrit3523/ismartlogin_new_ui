import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:google_fonts/google_fonts.dart';

// Screens
import 'package:ismart_login/src/features/profile/presentation/pages/profile_screen.dart';
import 'package:ismart_login/src/features/leave/presentation/pages/leave_statistics.dart';
import 'package:ismart_login/src/features/profile/presentation/pages/password_screen.dart';
import 'package:ismart_login/src/features/profile/presentation/pages/UserDeleteView.dart';
import 'package:ismart_login/src/features/sign/presentation/pages/signout_popup.dart';

// Admin Screens
// Verify path
import 'package:ismart_login/src/features/managements/presentation/pages/org_member_screen.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/org_department_screen.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/org_time_screen.dart';
import 'package:ismart_login/src/features/leave/presentation/pages/leave_settings.dart'; // Verify path
import 'package:ismart_login/src/features/managements/presentation/pages/org_screen.dart';

// Models & Server
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/model/itemMemberResultManage.dart';

import 'package:ismart_login/widgets/floating_bottom_navigation.dart';
import 'package:ismart_login/src/app/pages/main_page.dart'; // Import MainPage

class MenuScreen extends StatelessWidget {
  final List<ItemsMemberResultManage> itemMember;
  final Function onBadgeUpdate;

  const MenuScreen({
    Key? key,
    required this.itemMember,
    required this.onBadgeUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract member data safely
    var member = itemMember.isNotEmpty ? itemMember[0] : null;
    String images = member?.AVATAR ?? '';
    String fullname = (member?.NICKNAME != null && member!.NICKNAME!.isNotEmpty)
        ? member.NICKNAME!
        : (member?.FULLNAME ?? '');
    String orgName = member?.ORG_NAME ?? 'บริษัท เดอะสแตนดาร์ด จำกัด';
    String memberType = member?.MEMBER_TYPE ?? 'member';
    String orgId = member?.ORG_ID ?? '';
    String orgSubId = member?.ORG_SUB_ID ?? '';

    return Scaffold(
      floatingActionButton: FloatingClockFAB(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  MainPage(initialIndex: 1), // 1 = Front/Home
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                var begin = Offset(0.0, 1.0);
                var end = Offset.zero;
                var curve = Curves.ease;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                    position: animation.drive(tween), child: child);
              },
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: FloatingBottomNavigationBar(
        currentIndex: 4, // Menu is index 4
        onTap: (index) {
          if (index == 4) return; // Already here

          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  MainPage(initialIndex: index),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                var begin = Offset(0.0, 1.0);
                var end = Offset.zero;
                var curve = Curves.ease;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                    position: animation.drive(tween), child: child);
              },
            ),
          );
        },
      ),
      body: Stack(
        children: [
          // 1. Blue Gradient Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF21CCD4), // Light Blue
                  Color(0xFF0663F7), // Deep Blue
                ],
              ),
            ),
          ),

          // 2. Content
          SafeArea(
            child: SingleChildScrollView(
              padding:
                  EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
              child: Column(
                children: [
                  // Header Name & Avatar
                  _buildHeader(context, fullname, images),
                  SizedBox(height: 20),

                  // Organization Card
                  _buildOrgCard(orgName, member?.ORG_NAME ?? ''),

                  SizedBox(height: 20),

                  // Member Section (White Card)
                  _buildMemberSection(context),

                  SizedBox(height: 20),

                  // Admin Section (White Card) - Conditional
                  if (memberType != 'member') ...[
                    _buildAdminSection(context, orgId),
                    SizedBox(height: 20),
                  ],

                  // Logout Button
                  _buildLogoutButton(context),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String avatarUrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สวัสดี $name',
              style: GoogleFonts.kanit(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Color(0xFFFF80AB), // Pink ring
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            backgroundImage: (avatarUrl.isNotEmpty)
                ? NetworkImage(Server.url + avatarUrl)
                : null,
            child: (avatarUrl.isEmpty)
                ? Icon(Icons.person, color: Colors.grey, size: 30)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildOrgCard(String orgName, String orgDBName) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Org Logo / Initial
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xFF21CCD4).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              orgName.isNotEmpty ? orgName.substring(0, 1).toUpperCase() : 'C',
              style: GoogleFonts.kanit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF21CCD4),
              ),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orgName,
                  style: GoogleFonts.kanit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'สมาชิกในองค์กร (15)', // Static for now, or pass in
                  style: GoogleFonts.kanit(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, color: Colors.black54),
          )
        ],
      ),
    );
  }

  Widget _buildMemberSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สมาชิก',
            style: GoogleFonts.kanit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 15),
          _buildMenuItem(
            context,
            icon: Icons.person_outline,
            iconColor: Color(0xFF21CCD4),
            bgColor: Color(0xFFE0F7FA),
            title: 'ข้อมูลของคุณ',
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => ProfileScreen()));
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.show_chart,
            iconColor: Color(0xFF4CAF50),
            bgColor: Color(0xFFE8F5E9),
            title: 'สถิติการลา',
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => LeaveStatisticsScreen()));
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.payment, // Or ID card icon
            iconColor: Color(0xFFFFC107),
            bgColor: Color(0xFFFFFDE7),
            title: 'จัดการบัญชี',
            onTap: () {
              // Assuming this might be user deletion or generic account settings
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => UserDeleteView(key: UniqueKey())));
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.lock_outline,
            iconColor: Color(0xFFE91E63),
            bgColor: Color(0xFFFCE4EC),
            title: 'เปลี่ยนรหัสผ่าน',
            isLast: true,
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => PasswordChange()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSection(BuildContext context, String orgId) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ผู้ดูแลระบบ',
            style: GoogleFonts.kanit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 15),
          _buildMenuItem(
            context,
            icon: Icons.business, // Building
            iconColor: Color(0xFF2196F3),
            bgColor: Color(0xFFE3F2FD),
            title: 'จัดการองค์กร',
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => OrgManageScreen()));
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.people_outline,
            iconColor: Color(0xFF9C27B0),
            bgColor: Color(0xFFF3E5F5),
            title: 'กำหนดสิทธิ์สมาชิก',
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => OrgMemberScreen()));
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.access_time,
            iconColor: Color(0xFF673AB7),
            bgColor: Color(0xFFEDE7F6),
            title: 'ตั้งค่าเวลาทำงาน',
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => OrgTimeManage(org_id: orgId)));
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.description_outlined, // Branch/Note
            iconColor: Color(0xFFFF9800),
            bgColor: Color(0xFFFFF3E0),
            title: 'ตั้งค่าสาขา',
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => OrgDepartmentManage(org_id: orgId)));
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.login, // Door/Leave
            iconColor: Color(0xFF3F51B5),
            bgColor: Color(0xFFE8EAF6),
            title: 'ตั้งค่าลางาน',
            isLast: true,
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => LeaveSettingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => alert_signout(context),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Center(
              child: Text(
                'ออกจากระบบ',
                style: GoogleFonts.kanit(
                    fontSize: 16,
                    color: Colors.red,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon,
      required Color iconColor,
      required Color bgColor,
      required String title,
      required VoidCallback onTap,
      bool isLast = false}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.kanit(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

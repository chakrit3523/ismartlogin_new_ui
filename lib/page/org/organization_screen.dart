import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ismart_login/page/org/org_setup_screen.dart';
import 'package:ismart_login/page/org/join_screen.dart';
import 'package:ismart_login/page/sign/signout_popup.dart';
import 'package:location/location.dart';

class OrganizationScreen extends StatefulWidget {
  @override
  _OrganizationScreenState createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  Location _location = new Location();
  double lat = 0.0;
  double lng = 0.0;

  _getLocation() {
    _location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        lat = currentLocation.latitude != null
            ? currentLocation.latitude!.toDouble()
            : 0.0;
        lng = currentLocation.longitude != null
            ? currentLocation.longitude!.toDouble()
            : 0.0;
      });
    });
  }

  @override
  void initState() {
    _getLocation();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrgSetupScreen(
          orgName: '',
          // No callback - OrgSetupScreen will handle API call directly
        ),
      ),
    );
  }

  void _navigateToJoin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrganizationJoinScreen(),
      ),
    );
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
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/other/bg_login.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header with logout button
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          alert_signout(context);
                        },
                        child: Icon(
                          Icons.logout,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Spacer to push content down
                SizedBox(height: 30),

                // Logo
                Image.asset(
                  'assets/images/other/logo_.png',
                  height: 100,
                ),

                // Spacer
                Spacer(),

                // Title
                // Title removed

                SizedBox(height: 25),

                // Create Button (Gradient)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [Color(0xFF21CCD4), Color(0xFF0663F7)],
                          begin: Alignment(-0.97, -0.24), // 104deg
                          end: Alignment(0.97, 0.24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x29000000),
                            offset: Offset(0, 3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _navigateToCreate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                        label: Text(
                          "สร้างกลุ่ม/องค์กรใหม่",
                          style: GoogleFonts.kanit(
                            fontSize: 21,
                            color: Colors.white,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 15),

                // Styled Separator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.5),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          "หรือ",
                          style: GoogleFonts.kanit(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.5),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 15),
                // Join Button (Same Gradient style)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [Color(0xFF21CCD4), Color(0xFF0663F7)],
                          begin: Alignment(-0.97, -0.24), // 104deg
                          end: Alignment(0.97, 0.24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x29000000),
                            offset: Offset(0, 3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _navigateToJoin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: Icon(
                          Icons.login,
                          color: Colors.white,
                          size: 28,
                        ),
                        label: Text(
                          "เข้าร่วมกลุ่ม/องค์กร",
                          style: GoogleFonts.kanit(
                            fontSize: 21,
                            color: Colors.white,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

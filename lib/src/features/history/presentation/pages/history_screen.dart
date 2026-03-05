import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ismart_login/src/features/history/presentation/pages/history_all_screen.dart';
import 'package:ismart_login/src/features/history/presentation/pages/history_me_screen.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/future/member_manage_future.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/model/itemMemberResultManage.dart';
import 'package:ismart_login/system/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Removed unused TabController _controller;

  @override
  void initState() {
    // onLoadMemberManage();
    super.initState();
    Future.microtask(() async {
      await onLoadMemberManage();
      if (mounted) blocSetState(() {});
    });
  }

  List<ItemsMemberResultManage> _itemMember = [];
  Future<bool> onLoadMemberManage() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
    };
    print("apiGetMemberManageList : ${map}");
    await MemberManageFuture().apiGetMemberManageList(map).then((onValue) {
      if (mounted) {
        blocSetState(() {
          if (onValue[0].STATUS) {
            _itemMember = onValue[0].RESULT;
          }
        });
      }
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF21CCD4), // Cyan
              Color(0xFF0663F7), // Deep Blue
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _itemMember.isEmpty
                  ? Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF4EA9FB)),
                    )
                  : DefaultTabController(
                      length: (_itemMember[0].SUPER_STATUS == '1' ||
                              _itemMember[0].ADMIN_BRANCH_ID != '0')
                          ? 2
                          : 1,
                      child: Column(
                        children: [
                          // Tab Bar (Only show if allowed to see All, or always show?
                          // If only 1 tab (Me), showing a TabBar with 1 item is okay but a bit weird.
                          // But to keep UI consistent, let's keep it.
                          Container(
                            margin: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Color(0xFF4EA9FB), width: 1.5),
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.white,
                            ),
                            child: TabBar(
                              labelColor: Colors.white,
                              unselectedLabelColor: Color(0xFF4EA9FB),
                              labelStyle: GoogleFonts.kanit(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                              unselectedLabelStyle:
                                  GoogleFonts.kanit(fontSize: 16),
                              indicator: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: Color(0xFF4EA9FB),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              tabs: [
                                Tab(text: "เฉพาะคุณ"),
                                if (_itemMember[0].SUPER_STATUS == '1' ||
                                    _itemMember[0].ADMIN_BRANCH_ID != '0')
                                  Tab(text: "ทุกคน"),
                              ],
                            ),
                          ),
                          // Tab Views
                          Expanded(
                            child: TabBarView(
                              children: [
                                HistoryMeScreen(),
                                if (_itemMember[0].SUPER_STATUS == '1' ||
                                    _itemMember[0].ADMIN_BRANCH_ID != '0')
                                  HistoryAllScreen(
                                    status_super:
                                        _itemMember[0].SUPER_STATUS ?? '',
                                    admin_branch:
                                        _itemMember[0].ADMIN_BRANCH_ID ?? '',
                                    name_branch:
                                        _itemMember[0].NAME_BRANCH ?? '',
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

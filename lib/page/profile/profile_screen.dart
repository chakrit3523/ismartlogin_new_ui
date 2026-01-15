// ignore_for_file: deprecated_member_use, unused_local_variable

import 'dart:io';
import 'dart:convert'; // Added for JSON decoding

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:ismart_login/utils/dialog_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ismart_login/page/managements/future/department_manage_future.dart';
import 'package:ismart_login/page/managements/future/member_manage_future.dart';
import 'package:ismart_login/page/managements/future/time_manage_future.dart';
import 'package:ismart_login/page/managements/model/itemDepartmentResultManage.dart';
import 'package:ismart_login/page/managements/model/itemMemberResultManage.dart';
import 'package:ismart_login/page/managements/model/itemTimeResultMange.dart';
import 'package:ismart_login/page/managements/model/itemTimeResultDayManage.dart'; // Added
import 'package:ismart_login/page/profile/future/profile_future.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/system/shared_preferences.dart';
import 'package:ismart_login/widgets/bottom_menu_grid.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  String get validDepartmentValue {
    if (_resultDepartment.any((d) => d.ID == dropdownValueDepartment)) {
      return dropdownValueDepartment;
    }
    return '0';
  }

  String get validTimeValue {
    if (_itemTime.any((t) => t.ID == dropdownValueTime)) {
      return dropdownValueTime;
    }
    return '0';
  }

  // Setup
  XFile? _imageFile;
  dynamic _pickImageError;
  var org_id = "";

  bool _edit = false;
  String uid = '';
  String avatar = '';

  TextEditingController _inputName = TextEditingController();
  TextEditingController _inputLastname = TextEditingController();
  TextEditingController _inputNickname = TextEditingController();

  String dropdownValueTime = '0';
  String dropdownValueDepartment = '0';

  // Time Schedule Data
  List<ItemsTimeResultDayManage> _schedule = [];
  List<String> _dayNames = [
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์'
  ];

  // Helper to parse schedule
  void _updateSchedule() {
    print("Updating schedule for Time ID: $dropdownValueTime");
    _schedule = [];
    if (dropdownValueTime != '0') {
      try {
        var selectedTime = _itemTime.firstWhere(
            (t) => t.ID == dropdownValueTime,
            orElse: () => ItemsTimeResultManage(
                ID: '0',
                ORG_ID: '',
                SUBJECT: '',
                DESCRIPTION: '',
                CREATE_DATE: '',
                STATUS: ''));

        if (selectedTime.DESCRIPTION.isNotEmpty) {
          // The description is a JSON string of list of objects
          List<dynamic> jsonList = json.decode(selectedTime.DESCRIPTION);
          _schedule = jsonList
              .map((j) => ItemsTimeResultDayManage.fromJson(j))
              .toList();
        }
      } catch (e) {
        print("Error parsing schedule: $e");
      }
    }
    setState(() {});
  }

  // API Fetching
  List<ItemsTimeResultManage> _itemTime = [];
  Future<bool> onLoadGetAllTime() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
    };
    await TimeManageFuture().apiGetTimeManageList(map).then((onValue) {
      if (onValue[0].STATUS == true) {
        for (var time in onValue[0].RESULT) {
          if (_itemTime.indexWhere((t) => t.ID == time.ID) == -1) {
            _itemTime.add(time);
          }
        }
        _updateSchedule(); // Update schedule after loading times
        setState(() {});
      }
    });
    return true;
  }

  List<ItemsDepartmentResultManage> _resultDepartment = [];
  Future<bool> onLoadGetAllDepartment() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
    };
    await DepartManageFuture().apiGetDepartmentManageList(map).then((onValue) {
      if (onValue[0].STATUS == true) {
        for (var dep in onValue[0].RESULT) {
          if (_resultDepartment.indexWhere((d) => d.ID == dep.ID) == -1) {
            _resultDepartment.add(dep);
          }
        }
        setState(() {});
      }
    });
    return true;
  }

  List<ItemsMemberResultManage> _item = [];
  Future<bool> onLoadMemberManage() async {
    org_id = await SharedCashe.getItemsWay(name: 'org_id');
    AwesomeDialog loadingDialog =
        DialogHelper.showLoading(context, 'Loading...');
    Map map = {
      "org_id": org_id,
      "uid": await SharedCashe.getItemsWay(name: 'id'),
    };

    await MemberManageFuture().apiGetMemberManageList(map).then((onValue) {
      if (mounted) {
        loadingDialog.dismiss();
        setState(() {
          if (onValue[0].STATUS) {
            _item = onValue[0].RESULT;
            _getData();
          }
        });
      } else {
        loadingDialog.dismiss();
      }
    });
    return true;
  }

  _getData() async {
    if (_item.isEmpty) return;
    String fullname = _item[0].FULLNAME ?? '';
    String _nickname = _item[0].NICKNAME ?? '';
    String _uid = await SharedCashe.getItemsWay(name: 'id');
    String timeId = await SharedCashe.getItemsWay(name: 'time_id');
    String _avatar = _item[0].AVATAR ?? '';
    List name = fullname.split(",");
    _inputName.text = name[0];
    if (name.length > 1) {
      _inputLastname.text = name[1];
    }
    _inputNickname.text = _nickname;
    uid = _uid;
    avatar = _avatar;
    if (_item[0].ORG_SUB_ID.toString() != '') {
      dropdownValueDepartment = _item[0].ORG_SUB_ID ?? '';
    }
    if (_item[0].TIME_ID.toString() != '') {
      dropdownValueTime =
          _item[0].TIME_ID != "" ? (_item[0].TIME_ID ?? '') : timeId;
    }

    _updateSchedule();
    if (mounted) setState(() {});
  }

  Future<void> _handleClickFiles() async {
    final ImagePicker _picker = ImagePicker();
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      setState(() {
        _imageFile = image;
      });
    } catch (e) {
      setState(() {
        _pickImageError = e;
      });
    }
  }

  Future<dynamic> onUpdateProfile() async {
    // EasyLoading calls removed as ProfileFuture handles it with context
    await ProfileFuture().updateProfile(
      context: context,
      file: _imageFile?.path ?? '',
      uid: uid,
      name: _inputName.text,
      lastname: _inputLastname.text,
      nickname: _inputNickname.text,
      department: dropdownValueDepartment,
      time: dropdownValueTime,
      org_id: await SharedCashe.getItemsWay(name: 'org_id'),
    );
    // Success/dismiss handled in ProfileFuture
    setState(() {
      _edit = false;
    });
    return true;
  }

  @override
  void initState() {
    super.initState();

    _resultDepartment.add(ItemsDepartmentResultManage(
      ID: '0',
      SUBJECT: '- เลือก -',
      PARENT_ID: '',
      INVITE_CODE: '',
      LATITUDE: '',
      LONGTITUDE: '',
      RADIUS: '',
      CREATE_DATE: '',
      UPDATE_DATE: '',
      NOTI: '',
      STATUS: '',
      SEQ: '',
      TIME_ID: '',
    ));
    _itemTime.add(ItemsTimeResultManage(
      ID: '0',
      SUBJECT: '- เลือก -',
      ORG_ID: '',
      DESCRIPTION: '',
      CREATE_DATE: '',
      STATUS: '',
    ));
    onLoadMemberManage();
    onLoadGetAllDepartment();
    onLoadGetAllTime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
          bottom: false,
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios,
                          color:
                              Colors.transparent), // Hidden but keeps spacing
                      onPressed: () {}, // Removed functionality
                    ),
                    Text(
                      'ข้อมูลของคุณ',
                      style: GoogleFonts.kanit(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Visibility(
                      visible: !_edit,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _edit = true;
                          });
                        },
                        icon: Icon(Icons.edit, color: Colors.white, size: 18),
                        label: Text(
                          'แก้ไข',
                          style: GoogleFonts.kanit(color: Colors.white),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: _edit, // Placeholder to balance row
                      child: SizedBox(width: 80),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Profile Image
                          _buildProfileImage(),
                          SizedBox(height: 30),

                          // Form Fields
                          _buildFormFields(),

                          SizedBox(height: 20),

                          // Work Schedule Table
                          if (dropdownValueTime != '0' && _schedule.isNotEmpty)
                            _buildScheduleTable(),

                          SizedBox(height: 30),

                          // Bottom Menu
                          if (!_edit) ...[
                            BottomMenuGrid(
                              uid: uid,
                              lat:
                                  0.0, // Profile might not have live location, pass 0 or current loc if available.
                              long: 0.0,
                              timeId: dropdownValueTime,
                            ),
                            SizedBox(height: 30),
                          ],

                          // Action Buttons
                          if (_edit) _buildActionButtons(),
                          SizedBox(height: 40), // Bottom padding
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: () {
        if (_edit) {
          _handleClickFiles();
        }
      },
      child: Center(
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ],
              ),
              child: ClipOval(
                child: _getImageWidget(),
              ),
            ),
            if (_edit)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF21CCD4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _getImageWidget() {
    if (_imageFile != null) {
      return Image.file(File(_imageFile!.path), fit: BoxFit.cover);
    } else if (avatar.isNotEmpty) {
      return Image.network(Server.url + avatar, fit: BoxFit.cover);
    } else {
      return Icon(Icons.person, size: 60, color: Colors.grey[400]);
    }
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Row 1: Name | Lastname
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _inputName,
                label: 'ชื่อ',
                hint: 'ชื่อจริง',
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: _buildTextField(
                controller: _inputLastname,
                label: 'นามสกุล',
                hint: 'นามสกุล',
              ),
            ),
          ],
        ),
        SizedBox(height: 15),

        // Row 2: Nickname
        _buildTextField(
          controller: _inputNickname,
          label: 'ชื่อเล่น',
          hint: 'ชื่อเรียกในองค์กร',
        ),
        SizedBox(height: 15),

        // Branch Dropdown
        _buildDropdown(
          label: 'สาขา',
          value: validDepartmentValue,
          items: _resultDepartment
              .map((e) => DropdownMenuItem(value: e.ID, child: Text(e.SUBJECT)))
              .toList(),
          onChanged: (val) {
            setState(() {
              dropdownValueDepartment = val.toString();
            });
          },
        ),
        SizedBox(height: 15),

        // Time Dropdown
        _buildDropdown(
          label: 'เวลาทำงาน',
          value: validTimeValue,
          items: _itemTime
              .map((e) => DropdownMenuItem(value: e.ID, child: Text(e.SUBJECT)))
              .toList(),
          onChanged: (val) {
            setState(() {
              dropdownValueTime = val.toString();
              _updateSchedule();
            });
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.kanit(fontSize: 14, color: Colors.grey[600])),
        SizedBox(height: 5),
        TextFormField(
          controller: controller,
          enabled: _edit, // Enable only in edit mode
          style: GoogleFonts.kanit(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: _edit
                ? Colors.white
                : Colors.grey[50], // Grey out when disabled
            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            hintText: hint,
            hintStyle: GoogleFonts.kanit(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            disabledBorder: OutlineInputBorder(
              // Style for disabled state
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Colors
                      .transparent), // Removing border for cleaner look in read-only
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF21CCD4), width: 2),
            ),
          ),
          validator: (val) =>
              val == null || val.isEmpty ? 'กรุณาระบุข้อมูล' : null,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
                flex: 2,
                child: Text(label,
                    style: GoogleFonts.kanit(
                        fontSize: 16, fontWeight: FontWeight.w500))),
            Expanded(
              flex: 3,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: _edit
                    ? DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: value,
                          items: items,
                          onChanged: onChanged,
                          icon: Icon(Icons.keyboard_arrow_down,
                              color: Colors.grey),
                          style: GoogleFonts.kanit(
                              fontSize: 16, color: Colors.black87),
                          isExpanded: true,
                        ),
                      )
                    : Padding(
                        // Read-only view for dropdown
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          items
                                  .firstWhere((item) => item.value == value,
                                      orElse: () => DropdownMenuItem(
                                          value: '0', child: Text('-')))
                                  .child is Text
                              ? (items
                                      .firstWhere((item) => item.value == value)
                                      .child as Text)
                                  .data!
                              : '-',
                          style: GoogleFonts.kanit(
                              fontSize: 16, color: Colors.black87),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50], // Light grey background for table area
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('วัน',
                        style: GoogleFonts.kanit(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600]))),
                Expanded(
                    flex: 3,
                    child: Center(
                        child: Text('เข้างาน',
                            style: GoogleFonts.kanit(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600])))),
                Expanded(
                    flex: 3,
                    child: Center(
                        child: Text('ออกงาน',
                            style: GoogleFonts.kanit(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600])))),
              ],
            ),
          ),
          Divider(),
          // Rows
          ...List.generate(7, (index) {
            // Find schedule for this day (index 0=Mon, ..., 6=Sun)
            // Careful: API might use 0-6 or 1-7. check `itemTimeResultDayManage` usage in `org_timedatail_screen.dart`
            // In `org_timedatail_screen.dart`: `_groupDayName` starts with Monday. `_inputTimeIn[_resultItemDay[i].DAY]`.
            // `org_timedatail_screen.dart` uses `_groupDayName` index 0 for Monday.
            // We will assume `ItemsTimeResultDayManage.DAY` corresponds to this index.

            var daySchedule = _schedule.firstWhere((s) => s.DAY == index,
                orElse: () => ItemsTimeResultDayManage(
                    DAY: index, TIME_START: '', TIME_END: ''));

            bool isHoliday =
                daySchedule.TIME_START.isEmpty && daySchedule.TIME_END.isEmpty;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: Text(_dayNames[index],
                          style: GoogleFonts.kanit(
                              fontSize: 15, fontWeight: FontWeight.w600))),
                  Expanded(
                    flex: 6,
                    child: isHoliday
                        ? Center(
                            child: Text('วันหยุด',
                                style:
                                    GoogleFonts.kanit(color: Colors.grey[400])))
                        : Row(
                            children: [
                              Expanded(
                                  child: Center(
                                      child: Text(daySchedule.TIME_START,
                                          style: GoogleFonts.kanit(
                                              fontSize: 15)))),
                              Text("-", style: TextStyle(color: Colors.grey)),
                              Expanded(
                                  child: Center(
                                      child: Text(daySchedule.TIME_END,
                                          style: GoogleFonts.kanit(
                                              fontSize: 15)))),
                            ],
                          ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Cancel Button
        Expanded(
          child: TextButton(
            onPressed: () {
              setState(() {
                _edit = false;
                _getData(); // Reset data
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey[400],
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.kanit(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(width: 20),
        // Confirm Button
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF21CCD4), Color(0xFF0663F7)]),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  onUpdateProfile();
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                'ตกลง',
                style: GoogleFonts.kanit(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ignore_for_file: unnecessary_null_comparison, unused_field, unused_element, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:http/http.dart' as http;
import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/future/department_manage_future.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/model/itemDepartmentManage.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/model/itemDepartmentResultManage.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/style/page_style.dart';
import 'package:ismart_login/style/text_style.dart';
import 'package:ismart_login/system/shared_preferences.dart';
import 'package:ismart_login/system/widht_device.dart';
import 'package:location/location.dart';
import 'package:place_picker_google/place_picker_google.dart';

import 'future/time_manage_future.dart';
import 'model/itemTimeResultMange.dart';
import 'org_timedatail_screen.dart';

class OrgDepartmentDetailManage extends StatefulWidget {
  final String id;
  final String seq;
  final String org_id;
  final String type;
  final double lat;
  final double lng;
  final String noti;
  final Function refresh;

  OrgDepartmentDetailManage(
      {Key? key,
      required this.id,
      required this.org_id,
      required this.type,
      required this.lat,
      required this.lng,
      required this.seq,
      required this.refresh,
      required this.noti})
      : super(key: key);

  @override
  _OrgDepartmentDetailManageState createState() =>
      _OrgDepartmentDetailManageState();
}

class _OrgDepartmentDetailManageState extends State<OrgDepartmentDetailManage> {
  final _formKey = GlobalKey<FormState>();
  Location _location = new Location();
  double latMain = 0.0;
  double logMain = 0.0;
  Set<Marker> _markers = {};
  late StreamSubscription<LocationData> locationSubscription;
  _getLocation() {
    locationSubscription =
        _location.onLocationChanged.listen((LocationData currentLocation) {
      blocSetState(() {
        latMain = currentLocation.latitude != null
            ? currentLocation.latitude!.toDouble()
            : 0.0;
        logMain = currentLocation.longitude != null
            ? currentLocation.longitude!.toDouble()
            : 0.0;
      });
    });
  }

//-------
  TextEditingController _inputSubject = TextEditingController();
  TextEditingController _inputLat = TextEditingController();
  TextEditingController _inputLng = TextEditingController();
  TextEditingController _inputDegree = TextEditingController();
  TextEditingController _seq = TextEditingController();
  FocusNode _focusDegree = FocusNode();

  ///----
  bool _editLatlng = false;

  ///---- INSER/UPDATE -----
  _setDetailDepartmentToJson() async {
    EasyLoading.show();
    Map map = {
      "subject": _inputSubject.text,
      "org_id": widget.org_id != ''
          ? widget.org_id
          : await SharedCashe.getItemsWay(name: 'org_id'),
      "status": "1",
      "latitude": _lastMapPosition.latitude.toString(),
      "longitude": _lastMapPosition.longitude.toString(),
      "radius": _inputDegree.text,
      "id": widget.id,
      "type": widget.type,
      "time_id": dropdownValueTime,
    };
    print(json.encode(map).toString());
    onLoadPostDepartmet(map);
  }

  _insertSeq(String seq, String id) async {
    Map _map = {};
    _map.addAll({
      "id": id,
      "seq": seq,
    });
    print("_map : $_map");
    var body = json.encode(_map);
    final response = await http.Client().post(
      Uri.parse(Server().updateSeqOrg),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    var data = json.decode(response.body);
    print('insertSeq : $data');
    if (data != null) {
      if (data[0]['msg'].toString() == "success") {
        print('onLoadGetAllDepartment reload');
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      }
    }
  }

  List<ItemsDepartmentManagePostUpdate> _result = [];
  Future<bool> onLoadPostDepartmet(Map map) async {
    await DepartManageFuture().apiPostDepartmentManageList(map).then((onValue) {
      print(onValue[0].STATUS);
      print(onValue[0].MSG);
      if (onValue[0].STATUS == true) {
        EasyLoading.showSuccess('บันทึกแล้ว');
        Navigator.pop(context, true);
      } else {
        EasyLoading.showError('ล้มเหลว');
      }
    });
    return true;
  }

  ///----  / GET -----
  List<ItemsDepartmentResultManage> _resultItem = [];
  Future<bool> onLoadGetDepartment() async {
    Map map = {"org_id": widget.org_id, "id": widget.id};
    print("onLoadGetDepartment ${map}");

    await DepartManageFuture()
        .apiGetDepartmentManageList(map)
        .then((onValue) async {
      if (onValue[0].STATUS == true) {
        blocSetState(() {
          _resultItem = onValue[0].RESULT;
        });

        // ✅ ถ้าไม่มีพิกัดหรือเป็น 0 → ดึงตำแหน่งปัจจุบันแทน
        if (_resultItem.isNotEmpty) {
          final lat = double.tryParse(_resultItem[0].LATITUDE) ?? 0.0;
          final lng = double.tryParse(_resultItem[0].LONGTITUDE) ?? 0.0;
          if (lat == 0.0 && lng == 0.0) {
            await _getCurrentPosition();
          } else {
            _setShowValue();
          }
        } else {
          await _getCurrentPosition();
        }
      } else {
        await _getCurrentPosition();
      }
    });

    EasyLoading.dismiss();
    return true;
  }

  Future<void> _getCurrentPosition() async {
    try {
      LocationData currentLocation = await _location.getLocation();
      blocSetState(() {
        latMain = currentLocation.latitude ?? 0.0;
        logMain = currentLocation.longitude ?? 0.0;
        _center = LatLng(latMain, logMain);
        _lastMapPosition = LatLng(latMain, logMain);
        _inputLat.text = latMain.toString();
        _inputLng.text = logMain.toString();
        print("📍 ใช้ตำแหน่งปัจจุบัน: $latMain, $logMain");
      });
    } catch (e) {
      print("⚠️ ไม่สามารถดึงตำแหน่ง GPS ได้: $e");
    }
  }

  _setShowValue() {
    blocSetState(() {
      _inputSubject.text = _resultItem[0].SUBJECT;
      _inputLat.text = _resultItem[0].LATITUDE;
      _inputLng.text = _resultItem[0].LONGTITUDE;
      _inputDegree.text = _resultItem[0].RADIUS;
      latMain = widget.lat;
      logMain = widget.lng;
      _center = LatLng(widget.lat, widget.lng);
      _lastMapPosition = LatLng(widget.lat, widget.lng);
    });
  }

  //แผนที่
  Completer<GoogleMapController> _controller = Completer();
  Future<void> showPlacePicker() async {
    final LocationResult? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlacePicker(
          apiKey: "AIzaSyB91yhHGMRWDgLYajpg8ACtG5Dl1YUFFEw",
          initialLocation: LatLng(
            _lastMapPosition.latitude,
            _lastMapPosition.longitude,
          ),
          onPlacePicked: (LocationResult result) {
            Navigator.of(context).pop(result); // ✅ ส่งค่ากลับไป
          },
        ),
      ),
    );

    if (result != null && result.latLng != null) {
      print(
          "📍 พิกัดที่เลือก: ${result.latLng!.latitude}, ${result.latLng!.longitude}");

      // ✅ อัปเดตค่าใน State
      blocSetState(() {
        _center = result.latLng!;
        _lastMapPosition = result.latLng!;
        _inputLat.text = result.latLng!.latitude.toStringAsFixed(6);
        _inputLng.text = result.latLng!.longitude.toStringAsFixed(6);

        _markers = {
          Marker(
            markerId: MarkerId('current_marker'),
            position: result.latLng!,
            infoWindow: InfoWindow(
              title: "ตำแหน่งที่เลือก",
              snippet: result.formattedAddress ?? '',
            ),
          ),
        };
      });

      // ✅ เคลื่อนกล้องจริงใน Map
      try {
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(result.latLng!, 16),
        );
      } catch (e) {
        print("⚠️ AnimateCamera ล้มเหลว: $e");
      }
    }
  }

  ///---- GPS
  mapMark() {
    CameraPosition _kGooglePlex = CameraPosition(
      target: LatLng(latMain, logMain),
      zoom: 18,
    );
    return _kGooglePlex;
  }

  setMarker({required double lat, required double log}) {
    blocSetState(() {
      latMain = lat;
      logMain = log;
      _inputLat.text = latMain.toString();
      _inputLng.text = logMain.toString();
      _center = LatLng(latMain, logMain);
      _lastMapPosition = LatLng(latMain, logMain);
    });
  }

  addMarker() {
    Set<Marker> markers = {};
    markers.add(Marker(
      markerId: MarkerId('Marker_user'),
      position: LatLng(latMain, logMain),
      infoWindow: InfoWindow(title: 'ตำแหน่งที่ต้องการ'),
      icon: BitmapDescriptor.defaultMarkerWithHue(0),
    ));
    return markers;
  }

  String dropdownValueTime = '0';
  List<ItemsTimeResultManage> _itemTime = [];
  Future<bool> onLoadGetAllTime() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
    };
    await TimeManageFuture().apiGetTimeManageList(map).then((onValue) {
      if (onValue[0].STATUS == true) {
        blocSetState(() {
          _itemTime = onValue[0].RESULT;
          if (_resultItem != null && _resultItem.length > 0) {
            if (_resultItem[0].TIME_ID != '') {
              dropdownValueTime = _resultItem[0].TIME_ID;
            } else {
              dropdownValueTime = _itemTime[0].ID;
            }
          } else {
            dropdownValueTime = _itemTime[0].ID;
          }
          print("onloadTime : ${dropdownValueTime}");
        });
      }
    });
    return true;
  }

  @override
  void initState() {
    _inputDegree.text = '200';
    EasyLoading.dismiss();
    super.initState();
    // ✅ ป้องกัน _center ว่าง
    if (widget.lat == 0.0 && widget.lng == 0.0) {
      _getCurrentPosition();
    } else {
      setMarker(lat: widget.lat, log: widget.lng);
      if (widget.lat != 0.0 && widget.lng != 0.0) {
        _markers = {
          Marker(
            markerId: MarkerId('initial_location'),
            position: LatLng(widget.lat, widget.lng),
            infoWindow: InfoWindow(title: 'ตำแหน่งเริ่มต้น'),
          ),
        };
      }
    }

    if (widget.type == 'update') {
      onLoadGetDepartment();
    }

    _switchNoti = widget.noti != "0";
    onLoadGetAllTime();
  }

  bool _switchNoti = true;

  _updateNotiStatus(String status, String id) async {
    Map _map = {};
    _map.addAll({
      "id": id,
      "noti_status": status,
    });
    print("_map : $_map");
    var body = json.encode(_map);
    final response = await http.Client().post(
      Uri.parse(Server().updateNotiStatus),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    var data = json.decode(response.body);
    print('insertSeq : $data');
  }

  @override
  void dispose() {
    super.dispose();
  }

  ///-----
  late GoogleMapController _mapController;
  LatLng _center = const LatLng(13.7563, 100.5018); // 🏙 Bangkok default
  LatLng _lastMapPosition = const LatLng(13.7563, 100.5018);

  void _onCameraMove(CameraPosition position) {
    blocSetState(() {
      _lastMapPosition = position.target;
      _markers = {
        Marker(
          markerId: MarkerId('camera_move'),
          position: _lastMapPosition,
          infoWindow: InfoWindow(title: 'ตำแหน่งที่เลือก'),
        ),
      };
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (!_controller.isCompleted) {
      _controller.complete(controller); // ✅ บอกว่าพร้อมใช้งานแล้ว
    }
  }

  ///-----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: StylePage().background,
        child: SafeArea(
          child: GestureDetector(
            onTap: () {
              FocusScopeNode currentFocus = FocusScope.of(context);
              if (!currentFocus.hasPrimaryFocus) {
                currentFocus.unfocus();
              }
            },
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Container(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    AppBar(
                      centerTitle: true,
                      leading: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                      actions: [],
                      title: Text(
                        'สาขา',
                        style: StylesText.titleAppBar,
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0),
                      elevation: 0,
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 20, right: 20),
                      child: Container(
                        padding:
                            EdgeInsets.only(left: 10, right: 10, bottom: 20),
                        width: WidhtDevice().widht(context),
                        decoration: StylePage().boxWhite,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _inputSubject,
                                keyboardType: TextInputType.text,
                                style: TextStyle(
                                    fontFamily: FontStyles().FontFamily,
                                    fontSize: 24),
                                decoration: InputDecoration(
                                  hintText: 'ชื่อสาขา',
                                  hintStyle: TextStyle(
                                      fontFamily: FontStyles().FontFamily,
                                      fontSize: 24),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    child: Text(
                                      'รัศมีในการล็อกอิน',
                                      style: TextStyle(
                                          fontFamily: FontStyles().FontFamily,
                                          fontSize: 20),
                                    ),
                                  ),
                                  Container(
                                    width: 120,
                                    child: TextFormField(
                                      controller: _inputDegree,
                                      focusNode: _focusDegree,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                          fontFamily: FontStyles().FontFamily,
                                          fontSize: 24),
                                      decoration: InputDecoration(
                                        hintText: 'ควรมากกว่า 50',
                                        hintStyle: TextStyle(
                                            fontFamily: FontStyles().FontFamily,
                                            fontSize: 20),
                                        prefixIcon: Padding(
                                          padding: EdgeInsets.all(0),
                                          child: Icon(
                                            Icons.room,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    child: Text(
                                      'เมตร',
                                      style: TextStyle(
                                          fontFamily: FontStyles().FontFamily,
                                          fontSize: 20),
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.type == 'update')
                                Row(children: [
                                  Container(
                                    child: Text(
                                      'เรียง :',
                                      style: TextStyle(
                                        fontFamily: FontStyles().FontFamily,
                                        fontSize: 22,
                                        height: 1,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 50,
                                    height: 35,
                                    child: TextFormField(
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      controller:
                                          TextEditingController.fromValue(
                                        TextEditingValue(
                                          text: _seq.text != ''
                                              ? _seq.text
                                              : '${widget.seq}',
                                          selection: TextSelection.fromPosition(
                                            TextPosition(
                                                affinity:
                                                    TextAffinity.downstream,
                                                offset: '${widget.seq}'.length),
                                          ),
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                          fontFamily: FontStyles().FontFamily,
                                          fontSize: 24),
                                      onChanged: (text) {
                                        if (text.toString() != "") {
                                          _seq.text = text;
                                          _insertSeq(text.toString(),
                                              widget.id.toString());
                                        }
                                      },
                                    ),
                                  ),
                                ]),
                              Padding(
                                padding: EdgeInsets.all(5),
                              ),
                              Row(
                                children: [
                                  Container(
                                    child: Text(
                                      'กำหนดเวลาทำงาน : ',
                                      style: TextStyle(
                                        fontFamily: FontStyles().FontFamily,
                                        fontSize: 22,
                                        height: 1,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 120,
                                    child: DropdownButton(
                                      value: dropdownValueTime,
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.grey,
                                      ),
                                      iconSize: 24,
                                      elevation: 16,
                                      style: TextStyle(
                                        fontFamily: FontStyles().FontFamily,
                                        fontSize: 22,
                                        height: 1,
                                        color: Colors.black,
                                      ),
                                      isExpanded: true,
                                      underline: Container(
                                        height: 2,
                                        color: Colors.blue,
                                      ),
                                      onChanged: (newValue) {
                                        blocSetState(() {
                                          dropdownValueTime =
                                              newValue as String;
                                        });
                                        print('id time ' + dropdownValueTime);
                                      },
                                      items: _itemTime.length == 0
                                          ? <String>['0']
                                              .map<DropdownMenuItem<String>>(
                                                  (String value) {
                                              return DropdownMenuItem(
                                                child: Text('- เลือก -'),
                                                value: value,
                                              );
                                            }).toList()
                                          : _itemTime.map((map) {
                                              return DropdownMenuItem(
                                                child: Text(map.SUBJECT,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                                value: map.ID,
                                              );
                                            }).toList(),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (_formKey.currentState?.validate() ??
                                          false) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                OrgTimeDetailManage(
                                              id: '0',
                                              org_id: widget.org_id,
                                              type: 'insert',
                                              updateLoadTime: onLoadGetAllTime,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(left: 5),
                                      padding:
                                          EdgeInsets.only(left: 10, right: 10),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF079CFD),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        'เพิ่ม',
                                        style: TextStyle(
                                            fontFamily: FontStyles().FontFamily,
                                            color: Colors.white,
                                            fontSize: 24),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.all(5),
                              ),
                              Row(children: [
                                Container(
                                  child: Text(
                                    'การแจ้งเตือนก่อนเข้างาน 5 นาที : ',
                                    style: TextStyle(
                                      fontFamily: FontStyles().FontFamily,
                                      fontSize: 22,
                                      height: 1,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                FlutterSwitch(
                                  value: _switchNoti ? true : false,
                                  width: 60.0,
                                  height: 30.0,
                                  valueFontSize: 13.0,
                                  toggleSize: 30.0,
                                  borderRadius: 20.0,
                                  padding: 2.0,
                                  showOnOff: true,
                                  activeText: '',
                                  activeColor: Colors.green,
                                  inactiveText: '',
                                  inactiveColor: Colors.grey,
                                  onToggle: (state) {
                                    blocSetState(() {
                                      _switchNoti = state;
                                      if (_switchNoti) {
                                        var status = "1";
                                        _updateNotiStatus(status.toString(),
                                            widget.id.toString());
                                      } else {
                                        var status = "0";
                                        _updateNotiStatus(status.toString(),
                                            widget.id.toString());
                                      }
                                    });
                                  },
                                ),
                              ]),
                              Padding(
                                padding: EdgeInsets.all(5),
                              ),
                              Container(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          'เลื่อนแผนที่เพื่อเลือกที่ตั้งสาขา',
                                          style: TextStyle(
                                              fontFamily:
                                                  FontStyles().FontFamily,
                                              color: Colors.blue,
                                              fontSize: 22,
                                              height: 1),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 120,
                                      child: ElevatedButton(
                                        style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  Color(0xFFFF841B)),
                                        ),
                                        onPressed: () {
                                          showPlacePicker();
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.location_pin),
                                              Container(
                                                child: Text(
                                                  "คันหา",
                                                  style: TextStyle(
                                                      fontFamily: FontStyles()
                                                          .FontFamily,
                                                      color: Colors.white,
                                                      fontSize: 22,
                                                      height: 1),
                                                ),
                                                margin: EdgeInsets.symmetric(
                                                    horizontal: 8),
                                              ),
                                            ],
                                          ),
                                          width:
                                              MediaQuery.of(context).size.width,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Visibility(
                                visible: _editLatlng,
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.gps_fixed,
                                              size: 20,
                                              color: Colors.blue,
                                            ),
                                            Text(
                                              ' ละติจูด,ลองติจูด',
                                              style: TextStyle(
                                                  fontFamily:
                                                      FontStyles().FontFamily,
                                                  color: Colors.blue,
                                                  fontSize: 18),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _editLatlng
                                          ? GestureDetector(
                                              onTap: () {
                                                blocSetState(() {
                                                  _editLatlng = false;
                                                });
                                              },
                                              child: Container(
                                                padding: EdgeInsets.only(
                                                    left: 2, right: 3),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: Colors.blue,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.done,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                    Text(
                                                      'ตกลง',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontFamily:
                                                              FontStyles()
                                                                  .FontFamily,
                                                          fontSize: 18),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            )
                                          : GestureDetector(
                                              onTap: () {
                                                blocSetState(() {
                                                  _editLatlng = true;
                                                });
                                              },
                                              child: Container(
                                                padding: EdgeInsets.only(
                                                    left: 2, right: 2),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: Colors.grey,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.edit,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                    Text(
                                                      'กำหนดเอง',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontFamily:
                                                              FontStyles()
                                                                  .FontFamily,
                                                          fontSize: 18),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            )
                                    ],
                                  ),
                                ),
                              ),
                              Visibility(
                                visible: _editLatlng,
                                child: Container(
                                  color: _editLatlng
                                      ? Colors.white
                                      : Colors.grey[100],
                                  padding: EdgeInsets.only(left: 10),
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        enabled: _editLatlng,
                                        controller: _inputLat,
                                        keyboardType: TextInputType.text,
                                        style: TextStyle(
                                            fontFamily: FontStyles().FontFamily,
                                            fontSize: 24),
                                        decoration: InputDecoration(
                                          hintText: 'ละติจูด',
                                          hintStyle: TextStyle(
                                              fontFamily:
                                                  FontStyles().FontFamily,
                                              fontSize: 24),
                                        ),
                                      ),
                                      TextFormField(
                                        enabled: _editLatlng,
                                        controller: _inputLng,
                                        // focusNode: _focusUsername,
                                        keyboardType: TextInputType.text,
                                        style: TextStyle(
                                            fontFamily: FontStyles().FontFamily,
                                            fontSize: 24),
                                        decoration: InputDecoration(
                                          hintText: 'ลองติจูด',
                                          hintStyle: TextStyle(
                                              fontFamily:
                                                  FontStyles().FontFamily,
                                              fontSize: 24),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(5),
                              ),
                              Stack(
                                children: [
                                  Container(
                                    height: MediaQuery.of(context).size.height *
                                        0.35,
                                    child: GoogleMap(
                                      key: ValueKey(
                                          "${_center.latitude}_${_center.longitude}"), // ✅ บังคับ refresh
                                      onMapCreated: _onMapCreated,
                                      myLocationEnabled: true,
                                      initialCameraPosition: CameraPosition(
                                        target: _center,
                                        zoom: 15.0,
                                      ),
                                      onCameraMove: _onCameraMove,
                                      // markers: _markers, // ✅ เพิ่มหมุดเข้าไป
                                    ),
                                  ),
                                  Container(
                                    height: MediaQuery.of(context).size.height *
                                        0.35,
                                    child: Center(
                                      child: Icon(Icons.location_pin,
                                          size: 50, color: Colors.red),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 20,
                                    left: 20,
                                    child: Text(
                                      'Lat: ${_lastMapPosition.latitude.toStringAsFixed(6)}, Lng: ${_lastMapPosition.longitude.toStringAsFixed(6)}',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Visibility(
                                visible: _editLatlng ? false : true,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (_formKey.currentState?.validate() ??
                                            false) {
                                          _setDetailDepartmentToJson();
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.only(
                                            left: 25, right: 25),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF079CFD),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: Text(
                                          'บันทึก',
                                          style: TextStyle(
                                              fontFamily:
                                                  FontStyles().FontFamily,
                                              color: Colors.white,
                                              fontSize: 26),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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

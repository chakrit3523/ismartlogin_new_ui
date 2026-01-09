import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ismart_login/page/front/model/sumaryToDay_ontime.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/style/page_style.dart';
import 'package:url_launcher/url_launcher.dart';

class FrontCountOntimeScreen extends StatefulWidget {
  final List<ItemsSummaryToDay_Ontime> items;
  FrontCountOntimeScreen({Key? key, required this.items}) : super(key: key);
  @override
  _FrontCountOntimeScreenState createState() => _FrontCountOntimeScreenState();
}

class _FrontCountOntimeScreenState extends State<FrontCountOntimeScreen> {
  late List<ItemsSummaryToDay_Ontime> _items;
  @override
  void initState() {
    EasyLoading.dismiss();
    _items = widget.items;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: StylePage().background,
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                centerTitle: true,
                title: Text(
                  'ทันเวลา',
                  style: TextStyle(
                      fontFamily: FontStyles().FontFamily,
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.white.withValues(alpha: 0),
                elevation: 0,
              ),
              Expanded(
                child: _items.length > 0
                    ? _list()
                    : Center(
                        child: Text(
                          '-- ไม่มีข้อมูล --',
                          style: TextStyle(
                              fontFamily: FontStyles().FontFamily,
                              fontSize: 24,
                              color: Colors.grey[400]),
                        ),
                      ),
              ),
              Padding(padding: EdgeInsets.all(10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list() {
    return ListView.builder(
      padding: EdgeInsets.only(top: 10, bottom: 20, left: 16, right: 16),
      itemCount: _items.length,
      itemBuilder: (BuildContext context, int index) {
        var item = _items[index];
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon + Name
              Row(
                children: [
                  Icon(Icons.person, color: Colors.grey[400], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _subFullname(item.FULLNAME ?? '') +
                          ((item.NICKNAME ?? '') != ''
                              ? ' (${item.NICKNAME})'
                              : ''),
                      style: TextStyle(
                        fontFamily: FontStyles().FontThaiSans,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(height: 24, color: Colors.grey[200]),

              // Images & Times Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Check-In Column
                  Expanded(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            alert_show_images(context, 1, index);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Container(
                                color: Colors.grey[100],
                                child: Image.network(
                                  Server.url + (item.START_IMAGE_SMALL ?? ''),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                          child: Icon(Icons.image_not_supported,
                                              color: Colors.grey[300])),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          (item.START_TIME ?? '') + ' น.',
                          style: TextStyle(
                            fontFamily: FontStyles().FontFamily,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        if (item.START_LOCATION_STATUS == '1')
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'ไม่อยู่ในพื้นที่ : ' +
                                  (item.START_LOCATION_SUB_STATUS ?? ''),
                              style: TextStyle(
                                fontFamily: FontStyles().FontFamily,
                                fontSize: 12,
                                color: Colors.redAccent,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  // Check-Out Column
                  Expanded(
                    child: item.END_TIME != ''
                        ? Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  alert_show_images(context, 2, index);
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Container(
                                      color: Colors.grey[100],
                                      child: Image.network(
                                        Server.url +
                                            (item.END_IMAGE_SMALL ?? ''),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error,
                                                stackTrace) =>
                                            Center(
                                                child: Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey[300])),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                (item.END_TIME ?? '') + ' น.',
                                style: TextStyle(
                                  fontFamily: FontStyles().FontFamily,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              if (item.END_STATUS != '0')
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    _getEndStatus(item.END_STATUS ?? ''),
                                    style: TextStyle(
                                      fontFamily: FontStyles().FontFamily,
                                      fontSize: 12,
                                      color: Colors.redAccent,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          )
                        : SizedBox(), // Empty if no checkout
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  _getStatusLocation(String _status) {
    String _txt = '';
    if (_status != '') {
      List _list = json.decode(_status);
      List _checkboxListTile = ['โปรแกรมระบุตำแหน่งผิดพลาด', 'ทำงานนอกสถานที่'];
      if (_list.length > 0) {
        for (int i = 0; i < _list.length; i++) {
          _txt += _checkboxListTile[int.parse(_list[i])] + ', ';
        }
      }
    }

    return _txt;
  }

  _getEndStatus(String _status) {
    String _txt = '';
    if (_status != '' && _status != '0') {
      List _checkboxListTile = ['ออกงานก่อนเวลา', ''];
      _txt = _checkboxListTile[int.parse(_status) - 1];
    }
    return _txt;
  }

  alert_show_images(BuildContext context, int _status, int index) async {
    // Determine data based on status (1 = Start/Check-in, 2 = End/Check-out)
    String imageUrl = _status == 1
        ? (_items[index].START_IMAGE ?? '')
        : (_items[index].END_IMAGE ?? '');
    String dateTh = _items[index].CREATE_DATE_TH ?? '';
    String time = _status == 1
        ? (_items[index].START_TIME ?? '')
        : (_items[index].END_TIME ?? '');
    bool hasLocation = _status == 1
        ? (_items[index].START_LOCATION_STATUS == '1')
        : (_items[index].START_LOCATION_STATUS ==
            '1'); // Note: Original logic checked START_LOCATION_STATUS for both? Let's check logic.
    // Logic check:
    // Original Check-in: _items[index].START_LOCATION_STATUS == '1' -> launch START_LATITUDE
    // Original Check-out: _items[index].START_LOCATION_STATUS == '1' -> launch START_LATITUDE ?? Wait.
    // Looking at original code:
    // for _status == 2 (End):
    //   it checked `_items[index].START_LOCATION_STATUS == '1'`
    //   BUT it launched `START_LATITUDE`/`START_LONGITUDE`.
    //   This seems like a BUG in the original code or a weird logic (using start location for end?).
    //   However, for End, it SHOULD likely be END_LATITUDE.
    //   Let's see: `_items[index]` has `END_LATITUDE`, `END_LONGITUDE`.
    //   I will try to use the correct one for End if available, or fall back to what it was if unsure.
    //   Actually, looking carefully at the original code's lines ~428:
    //   For _status != 1 (End), it checked `START_LOCATION_STATUS == '1'` and used `START_LATITUDE`.
    //   This is extremely suspicious.
    //   However, if I look at line 366 (Check-in block): `query=` + `END_LATITUDE` + `,` + `END_LATITUDE`.
    //   WAIT. The original code was:
    //   Block 1 (Status 1/Start): Checks `START_LOCATION_STATUS`. Uses `END_LATITUDE` ??? That's definitely a bug in old code.
    //   Block 2 (Status 2/End): Checks `START_LOCATION_STATUS`. Uses `START_LATITUDE`.
    //
    //   I will Fix this logic to be sane:
    //   Status 1 (Start): Check `START_LOCATION_STATUS`, use `START_LATITUDE`/`START_LONGITUDE`.
    //   Status 2 (End): Check `END_LOCATION_STATUS`? The model has `END_LOCATION_NOT` and `END_STATUS`.
    //   Note: The model `ItemsSummaryToDay_Ontime` has `START_LATITUDE`, `END_LATITUDE`.
    //   I will assume:
    //   If Status 1: Use Start data.
    //   If Status 2: Use End data.
    //   The field `START_LOCATION_STATUS` might indicate if location tracking was on.
    //   Let's assume `START_LOCATION_STATUS` applies to the whole record or check specific fields.
    //   Based on the previous screen's list, we display "ไม่อยู่ในพื้นที่" for Start and End separately.
    //   I'll attempt to use the respective coordinates.

    String lat = _status == 1
        ? (_items[index].START_LATITUDE ?? '')
        : (_items[index].END_LATITUDE ?? '');
    String long = _status == 1
        ? (_items[index].START_LONGITUDE ?? '')
        : (_items[index].END_LONGITUDE ?? '');

    // Fallback if empty/invalid, don't show map button?

    return showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Image
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: Image.network(
                      Server.url + imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 300,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 300,
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image,
                            size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                ),

                // 2. Info Section
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'วันที่ $dateTh เวลา $time',
                        style: GoogleFonts.kanit(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500, // Medium
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),

                      // Location Button (if coordinates exist)
                      if (lat.isNotEmpty && long.isNotEmpty && lat != "null")
                        GestureDetector(
                          onTap: () async {
                            String url =
                                'https://www.google.com/maps/search/?api=1&query=$lat,$long';
                            final _uri = Uri.parse(url); if (await canLaunchUrl(_uri)) {
                              await launchUrl(Uri.parse(url));
                            } else {
                              // EasyLoading.showError('Could not launch map');
                              print('Could not launch $url');
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius:
                                  BorderRadius.circular(50), // Capsule
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(FontAwesomeIcons.locationDot,
                                    size: 16, color: Colors.grey[600]),
                                SizedBox(width: 8),
                                Text(
                                  'สถานที่',
                                  style: GoogleFonts.kanit(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      SizedBox(height: 16),

                      // Close Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            'ปิด',
                            style: GoogleFonts.kanit(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _subFullname(String fullname) {
    String name = '';
    List list = fullname.split(",");
    name = list[0];
    if (list.length > 1) {
      name += ' ' + list[1];
    }
    return name;
  }
}

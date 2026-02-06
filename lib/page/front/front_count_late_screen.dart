import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ismart_login/page/front/model/sumaryToDay_late.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/style/page_style.dart';
import 'package:ismart_login/system/widht_device.dart';
import 'package:ismart_login/page/map/osm_map_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_gifs/loading_gifs.dart';
import 'package:url_launcher/url_launcher.dart';

class FrontCountLateScreen extends StatefulWidget {
  final List<ItemsSummaryToDay_Late> items;
  const FrontCountLateScreen({super.key, required this.items});
  @override
  _FrontCountLateScreenState createState() => _FrontCountLateScreenState();
}

class _FrontCountLateScreenState extends State<FrontCountLateScreen> {
  late List<ItemsSummaryToDay_Late> _items;
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
                  'สาย',
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
                child: Container(
                  margin: EdgeInsets.only(left: 20, right: 20),
                  padding:
                      EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 5),
                  width: WidhtDevice().widht(context),
                  decoration: StylePage().boxWhite,
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
              ),
              Padding(padding: EdgeInsets.all(10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list() {
    return Scrollbar(
      child: ListView.separated(
        separatorBuilder: (BuildContext context, int index) => const Divider(),
        padding: EdgeInsets.all(8),
        itemCount: _items.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.only(top: 5, bottom: 5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 20,
                      color: Colors.grey,
                    ),
                    Padding(padding: EdgeInsets.all(2)),
                    Expanded(
                      child: Container(
                        child: Text(
                          _subFullname(_items[index].FULLNAME ?? '') +
                              (_items[index].NICKNAME != null &&
                                      _items[index].NICKNAME != ''
                                  ? ' (' + _items[index].NICKNAME! + ')'
                                  : ''),
                          style: TextStyle(
                              fontFamily: FontStyles().FontThaiSans,
                              fontSize: 24,
                              height: 1),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(padding: EdgeInsets.all(3)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          alert_show_images(context, 1, index);
                        },
                        child: Column(
                          children: [
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                              ),
                              child: Image.network(
                                Server.url +
                                    (_items[index].START_IMAGE_SMALL ?? ''),
                                fit: BoxFit.cover,
                                width: WidhtDevice().widht(context) / 2,
                              ),
                            ),
                            Container(
                              child: Text(
                                _items[index].DESCRIPTION ?? '',
                                style: TextStyle(
                                    fontFamily: FontStyles().FontThaiSans,
                                    fontSize: 20,
                                    height: 1.2),
                              ),
                            ),
                            _items[index].START_NOTE != ''
                                ? Container(
                                    alignment: Alignment.center,
                                    width: WidhtDevice().widht(context) / 3.5,
                                    child: Text(
                                      _items[index].START_NOTE ?? '',
                                      style: TextStyle(
                                          fontFamily: FontStyles().FontFamily,
                                          fontSize: 18,
                                          height: 1,
                                          color: Colors.red[200]),
                                    ),
                                  )
                                : Container(
                                    height: 0,
                                  ),
                            _items[index].START_LOCATION_STATUS == '1' &&
                                    _items[index].START_LOCATION_SUB_STATUS !=
                                        ''
                                ? GestureDetector(
                                    child: Container(
                                      alignment: Alignment.center,
                                      width: WidhtDevice().widht(context) / 3.5,
                                      child: Text(
                                        'ไม่อยู่ในพื้นที่ : ' +
                                            _items[index]
                                                .START_LOCATION_SUB_STATUS
                                                .toString(),
                                        style: TextStyle(
                                            fontFamily: FontStyles().FontFamily,
                                            fontSize: 18,
                                            height: 1.2,
                                            color: Colors.red[200]),
                                      ),
                                    ),
                                  )
                                : Container(
                                    height: 0,
                                  ),
                            _items[index].START_ADDRESS != null &&
                                    _items[index].START_ADDRESS != ''
                                ? Container(
                                    alignment: Alignment.center,
                                    width: WidhtDevice().widht(context) / 3.5,
                                    child: Text(
                                      _items[index].START_ADDRESS!,
                                      style: TextStyle(
                                          fontFamily: FontStyles().FontFamily,
                                          fontSize: 14,
                                          color: Colors.grey[600]),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : Container(
                                    height: 0,
                                  ),
                          ],
                        ),
                      ),
                    ),
                    Padding(padding: EdgeInsets.all(2)),
                    Expanded(
                      child: _items[index].END_TIME == ''
                          ? Container()
                          : GestureDetector(
                              onTap: () {
                                print("logout");
                                alert_show_images(context, 2, index);
                              },
                              child: Column(
                                children: [
                                  Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.white,
                                    ),
                                    child: Image.network(
                                      Server.url +
                                          (_items[index].END_IMAGE_SMALL ?? ''),
                                      fit: BoxFit.cover,
                                      width: WidhtDevice().widht(context) / 2,
                                    ),
                                  ),
                                  Container(
                                    child: Text(
                                      (_items[index].END_TIME ?? '') + ' น.',
                                      style: TextStyle(
                                          fontFamily: FontStyles().FontThaiSans,
                                          fontSize: 20),
                                    ),
                                  ),
                                  _items[index].END_STATUS != '0'
                                      ? Container(
                                          alignment: Alignment.center,
                                          child: Column(
                                            children: [
                                              Container(
                                                child: Text(
                                                  _getEndStatus(_items[index]
                                                          .END_STATUS ??
                                                      ''),
                                                  style: TextStyle(
                                                      fontFamily: FontStyles()
                                                          .FontFamily,
                                                      fontSize: 18,
                                                      height: 1,
                                                      color: Colors.red[200]),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Container(
                                          height: 0,
                                        ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
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
    print("getEndStatus : ${int.parse(_status) - 1}");
    if (_status != '' && _status != '0') {
      List _checkboxListTile = [
        'ออกงานก่อนเวลา',
        'ออกงานก่อนเวลา',
        'ออกงานก่อนเวลา'
      ];
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

    String lat = _status == 1
        ? (_items[index].START_LATITUDE ?? '')
        : (_items[index].END_LATITUDE ?? '');
    String long = _status == 1
        ? (_items[index].START_LONGITUDE ?? '')
        : (_items[index].END_LONGITUDE ?? '');

    // Check if outside area
    bool isOutsideArea = _items[index].START_LOCATION_STATUS == '1';
    String address = _items[index].START_ADDRESS ?? '';

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
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: Image.network(
                      Server.url + imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 300,
                          child: Center(
                            child: FadeInImage.assetNetwork(
                              placeholder: cupertinoActivityIndicatorSmall,
                              placeholderScale: 5,
                              image: Server.url + imageUrl,
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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'วันที่ $dateTh เวลา $time',
                        style: GoogleFonts.kanit(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Always show location details if lat/long available
                      if (lat.isNotEmpty &&
                          long.isNotEmpty &&
                          lat != "null") ...[
                        SizedBox(height: 12),
                        // Lat/Long display
                        Text(
                          'พิกัด: $lat, $long',
                          style: GoogleFonts.kanit(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        // Address display (red if outside, grey if inside)
                        if (address.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OSMMapPage(
                                      lat: double.tryParse(lat) ?? 0.0,
                                      lon: double.tryParse(long) ?? 0.0,
                                      address: address,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.locationDot,
                                    size: 14,
                                    color: isOutsideArea
                                        ? Colors.red
                                        : Colors.grey[600],
                                  ),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      address,
                                      style: GoogleFonts.kanit(
                                        fontSize: 14,
                                        color: isOutsideArea
                                            ? Colors.red
                                            : Colors.grey[700],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        SizedBox(height: 16),

                        // Map buttons Row
                        Row(
                          children: [
                            // Longdo Map Button
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (lat.isNotEmpty &&
                                      long.isNotEmpty &&
                                      lat != "null") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OSMMapPage(
                                          lat: double.tryParse(lat) ?? 0.0,
                                          lon: double.tryParse(long) ?? 0.0,
                                          address: address,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FaIcon(FontAwesomeIcons.map,
                                          size: 14, color: Colors.blue),
                                      SizedBox(width: 6),
                                      Text(
                                        'ดูแผนที่',
                                        style: GoogleFonts.kanit(
                                          fontSize: 14,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            // Google Maps Navigation Button
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  if (lat.isNotEmpty &&
                                      long.isNotEmpty &&
                                      lat != "null") {
                                    String url =
                                        'https://www.google.com/maps/dir/?api=1&destination=$lat,$long&travelmode=driving';
                                    final uri = Uri.parse(url);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    }
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FaIcon(FontAwesomeIcons.diamondTurnRight,
                                          size: 14, color: Colors.green),
                                      SizedBox(width: 6),
                                      Text(
                                        'นำทาง',
                                        style: GoogleFonts.kanit(
                                          fontSize: 14,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      SizedBox(height: 16),

                      // Close Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
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

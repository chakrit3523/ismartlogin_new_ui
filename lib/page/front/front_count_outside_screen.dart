import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ismart_login/page/front/model/sumaryToDay_outside.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/style/page_style.dart';
import 'package:ismart_login/system/widht_device.dart';
import 'package:ismart_login/page/map/osm_map_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_gifs/loading_gifs.dart';
import 'package:url_launcher/url_launcher.dart';

class FrontCountOutsideScreen extends StatefulWidget {
  final List<ItemsSummaryToDay_Outside> items;
  final String? scheduledEndTime;
  const FrontCountOutsideScreen(
      {Key? key, required this.items, this.scheduledEndTime})
      : super(key: key);
  @override
  _FrontCountOutsideScreenState createState() =>
      _FrontCountOutsideScreenState();
}

class _FrontCountOutsideScreenState extends State<FrontCountOutsideScreen> {
  late List<ItemsSummaryToDay_Outside> _items;
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
                  'นอกสถานที่',
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
          // List<ItemsAttendOutsideDetailPop> _resultItemDetail = [];
          // _resultItemDetail = List.from(
          //   json.decode(_items[index].START_NOTE).map(
          //         (m) => ItemsAttendOutsideDetailPop.fromJson(m),
          //       ),
          // );
          return Container(
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
                          _subFullname(_items[index].FULLNAME) +
                              (_items[index].NICKNAME != ''
                                  ? ' (' + _items[index].NICKNAME + ')'
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              alert_show_images(context, 1, index);
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(
                                  // mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _items[index].START_ADDRESS != ''
                                                  ? _items[index].START_ADDRESS
                                                  : _items[index]
                                                      .START_LOCATION_SUB_STATUS,
                                              style: TextStyle(
                                                fontFamily:
                                                    FontStyles().FontFamily,
                                                fontSize: 20,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                                height: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Expanded(
                                    //   flex: 2,
                                    //   child: Container(
                                    //     child: Column(
                                    //       mainAxisAlignment:
                                    //           MainAxisAlignment.start,
                                    //       crossAxisAlignment:
                                    //           CrossAxisAlignment.start,
                                    //       children: [
                                    //         Text(
                                    //           _resultItemDetail[0].TOPIC != ''
                                    //               ? _resultItemDetail[0].TOPIC
                                    //               : '-',
                                    //           style: TextStyle(
                                    //             fontFamily:
                                    //                 FontStyles().FontFamily,
                                    //             fontSize: 20,
                                    //             color: Colors.blue,
                                    //             fontWeight: FontWeight.bold,
                                    //             height: 1,
                                    //           ),
                                    //         ),
                                    //         Text(
                                    //           _resultItemDetail[0]
                                    //                       .DESCRIPTION !=
                                    //                   ''
                                    //               ? _resultItemDetail[0]
                                    //                   .DESCRIPTION
                                    //               : '',
                                    //           style: TextStyle(
                                    //             fontFamily:
                                    //                 FontStyles().FontFamily,
                                    //             fontSize: 19,
                                    //             color: Colors.black,
                                    //             height: 1,
                                    //           ),
                                    //         )
                                    //       ],
                                    //     ),
                                    //   ),
                                    // ),
                                    _items[index].START_IMAGE_SMALL != ''
                                        ? Expanded(
                                            flex: 1,
                                            child: Container(
                                              height: 100,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: Colors.white,
                                              ),
                                              child: Image.network(
                                                Server.url +
                                                    _items[index]
                                                        .START_IMAGE_SMALL,
                                                fit: BoxFit.cover,
                                                width: WidhtDevice()
                                                        .widht(context) /
                                                    2,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            width: 0,
                                          ),
                                  ],
                                ),
                                Padding(padding: EdgeInsets.all(2)),
                                Container(
                                  alignment: Alignment.center,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              FaIcon(
                                                FontAwesomeIcons.clock,
                                                size: 16,
                                              ),
                                              Padding(
                                                  padding: EdgeInsets.all(2)),
                                              Text(
                                                _items[index].START_TIME +
                                                    ' น.',
                                                style: TextStyle(
                                                    fontFamily: FontStyles()
                                                        .FontThaiSans,
                                                    fontSize: 24),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                          child: Container(
                                        alignment: Alignment.center,
                                        child: GestureDetector(
                                            onTap: () async {
                                              String url =
                                                  'https://www.google.com/maps/search/?api=1&query=' +
                                                      _items[index]
                                                          .START_LATITUDE +
                                                      ',' +
                                                      _items[index]
                                                          .START_LONGITUDE +
                                                      '';
                                              final _uri = Uri.parse(url);
                                              if (await canLaunchUrl(_uri)) {
                                                await launchUrl(Uri.parse(url));
                                              } else {
                                                throw 'Could not launch $url';
                                              }
                                            },
                                            child: Container(
                                              padding: EdgeInsets.only(
                                                  top: 2, bottom: 2),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: Colors.grey[100]),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  FaIcon(
                                                    FontAwesomeIcons
                                                        .mapMarkedAlt,
                                                    size: 18,
                                                    color: Colors.grey[600],
                                                  ),
                                                  Padding(
                                                      padding:
                                                          EdgeInsets.all(2)),
                                                  Flexible(
                                                    child: Text(
                                                      _items[index]
                                                                  .START_ADDRESS !=
                                                              ''
                                                          ? _items[index]
                                                              .START_ADDRESS
                                                          : 'ดูพิกัด',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontFamily: FontStyles()
                                                            .FontFamily,
                                                        fontSize: _items[index]
                                                                    .START_ADDRESS !=
                                                                ''
                                                            ? 14
                                                            : 18,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  )
                                                ],
                                              ),
                                            )),
                                      )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
    return _status == '1' ? 'ออกงานก่อนเวลา' : '';
  }

  alert_show_images(BuildContext context, int _status, int index) async {
    // Determine data based on status (1 = Start/Check-in, 2 = End/Check-out)
    String imageUrl =
        _status == 1 ? _items[index].START_IMAGE : _items[index].END_IMAGE;
    String dateTh = _items[index].CREATE_DATE_TH;
    String time =
        _status == 1 ? _items[index].START_TIME : _items[index].END_TIME;

    String lat = _status == 1
        ? _items[index].START_LATITUDE
        : _items[index].END_LATITUDE;
    String long = _status == 1
        ? _items[index].START_LONGITUDE
        : _items[index].END_LONGITUDE;

    // For outside screen, always show address (they're already outside)
    String address = _status == 1
        ? _items[index].START_ADDRESS
        : (_items[index].END_ADDRESS != ''
            ? _items[index].END_ADDRESS
            : _items[index].START_ADDRESS);

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

                      // Always show location details for outside screen
                      if (lat != '' && long != '') ...[
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
                        // Address display (always red for outside screen)
                        if (address != '')
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
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      address,
                                      style: GoogleFonts.kanit(
                                        fontSize: 14,
                                        color: Colors.red,
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
                                  if (lat != '' && long != '') {
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
                                  if (lat != '' && long != '') {
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

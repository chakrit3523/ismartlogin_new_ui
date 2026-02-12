import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ismart_login/page/front/model/sumaryToDay_ontime.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/style/page_style.dart';
import 'package:ismart_login/page/map/osm_map_page.dart';
import 'package:url_launcher/url_launcher.dart';

class FrontCountOntimeScreen extends StatefulWidget {
  final List<ItemsSummaryToDay_Ontime> items;
  final String? scheduledEndTime;
  FrontCountOntimeScreen(
      {Key? key, required this.items, this.scheduledEndTime})
      : super(key: key);
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
                        if (item.START_ADDRESS != null &&
                            item.START_ADDRESS != '')
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              item.START_ADDRESS!,
                              style: TextStyle(
                                fontFamily: FontStyles().FontFamily,
                                fontSize: 12,
                                color: Colors.grey[600],
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
                              if (_isEarlyCheckout(
                                  item.END_TIME, item.END_STATUS))
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    _getEndStatus(),
                                    style: TextStyle(
                                      fontFamily: FontStyles().FontFamily,
                                      fontSize: 12,
                                      color: Colors.redAccent,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              if (item.END_ADDRESS != null &&
                                  item.END_ADDRESS != '')
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    item.END_ADDRESS!,
                                    style: TextStyle(
                                      fontFamily: FontStyles().FontFamily,
                                      fontSize: 12,
                                      color: Colors.grey[600],
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

  String _getEndStatus() {
    return 'ออกงานก่อนเวลา';
  }

  int? _parseTimeToMinutes(String? time) {
    if (time == null || time.isEmpty) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return (hour * 60) + minute;
  }

  bool _isEarlyCheckout(String? endTime, String? endStatus) {
    final endMinutes = _parseTimeToMinutes(endTime);
    final scheduledMinutes = _parseTimeToMinutes(widget.scheduledEndTime);
    if (endMinutes != null && scheduledMinutes != null) {
      return endMinutes < scheduledMinutes;
    }
    return (endStatus ?? '') == '1';
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
    String address = _status == 1
        ? (_items[index].START_ADDRESS ?? '')
        : (_items[index].END_ADDRESS ?? '');

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

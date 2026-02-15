import 'dart:convert';

import 'dart:async'; // Add async
import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Add google_maps_flutter
import 'package:ismart_login/src/features/front/presentation/pages/model/attendOutsideDescriptionPop.dart';
import 'package:ismart_login/src/features/history/presentation/pages/future/history_future.dart';
import 'package:ismart_login/src/features/history/presentation/pages/model/itemMyHistory.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/system/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryMeScreen extends StatefulWidget {
  @override
  _HistoryMeScreenState createState() => _HistoryMeScreenState();
}

class _HistoryMeScreenState extends State<HistoryMeScreen> {
  // Status labels
  List statusTimeOut = ['ลาไม่เต็มวัน', 'ทำงานนอกสถานที่'];
  List statusTimeIn = [
    'สาย',
    'ลาไม่เต็มวัน',
    'ลืมลงชื่อเข้างาน',
    'ทำงานนอกสถานที่'
  ];

  // Loading state
  bool isLoading = false;
  int start = 0;
  List<ItemsMyHistory> _result = [];

  // Date Range
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Statistics (calculated from results)
  int _onTimeCount = 0;
  int _lateCount = 0;
  int _outsideCount = 0;
  int _overtimeCount = 0;
  int _leaveCount = 0;

  @override
  void initState() {
    super.initState();
    onLoadHistoryMe(0);
  }

  Future<bool> onLoadHistoryMe(int _start) async {
    Map map = {
      "uid": await SharedCashe.getItemsWay(name: 'id'),
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "start": _start
    };
    print('apiGetHistoryMeList: $map');
    await HistoryFuture().apiGetHistoryMeList(map).then((onValue) {
      if (start == 0) {
        blocSetState(() {
          _result = onValue;
          _calculateStats();
        });
      } else {
        blocSetState(() {
          _result.addAll(onValue);
          isLoading = false;
          _calculateStats();
        });
      }
    });
    return true;
  }

  void _calculateStats() {
    _onTimeCount = 0;
    _lateCount = 0;
    _outsideCount = 0;
    _leaveCount = 0;

    for (var item in _result) {
      if (item.CID == '3') {
        _outsideCount++;
      } else if (item.START_STATUS == '1') {
        _lateCount++;
      } else if (item.START_STATUS == '0' && item.START_TIME.isNotEmpty) {
        _onTimeCount++;
      }
    }
    blocSetState(() {});
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF21CCD4),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      blocSetState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      start = 0;
      onLoadHistoryMe(0);
    }
  }

  String _formatThaiDate(DateTime date) {
    final thaiMonths = [
      '',
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.'
    ];
    int thaiYear = (date.year + 543) % 100;
    return '${date.day} ${thaiMonths[date.month]} $thaiYear';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDateRangeSelector(),
        _buildStatsRow(),
        Expanded(
          child: _result.isEmpty
              ? Center(
                  child: Text(
                    '-- ไม่มีข้อมูล --',
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      color: Colors.grey[400],
                    ),
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!isLoading &&
                        scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent) {
                      blocSetState(() {
                        start = start + 1;
                        onLoadHistoryMe(start);
                        isLoading = true;
                      });
                    }
                    return false;
                  },
                  child: _buildHistoryList(),
                ),
        ),
        if (isLoading)
          Container(
            height: 50,
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context, true),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatThaiDate(_startDate),
                      style: GoogleFonts.kanit(
                          fontSize: 14, color: Colors.grey[700]),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('ถึง', style: GoogleFonts.kanit(color: Colors.grey)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context, false),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatThaiDate(_endDate),
                      style: GoogleFonts.kanit(
                          fontSize: 14, color: Colors.grey[700]),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatItem('ทันเวลา', _onTimeCount, Color(0xFF21CCD4)),
          _buildStatItem('สาย', _lateCount, Color(0xFFFF9800)),
          _buildStatItem('นอกสถานที่', _outsideCount, Color(0xFFE91E63)),
          _buildStatItem('ล่วงเวลา', _overtimeCount, Color(0xFF2196F3)),
          _buildStatItem('ลา', _leaveCount, Color(0xFF4CAF50)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: GoogleFonts.kanit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: GoogleFonts.kanit(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12),
      itemCount: _result.length,
      itemBuilder: (context, index) {
        return _buildHistoryCard(index);
      },
    );
  }

  Widget _buildHistoryCard(int index) {
    final item = _result[index];
    final isOutside = item.CID == '3';
    final isLate = item.START_STATUS == '1';

    // Parse outside work details if applicable
    List<ItemsAttendOutsideDetailPop> outsideDetails = [];
    if (isOutside && item.START_NOTE.isNotEmpty) {
      try {
        outsideDetails = List.from(
          json.decode(item.START_NOTE).map(
                (m) => ItemsAttendOutsideDetailPop.fromJson(m),
              ),
        );
      } catch (e) {
        // Handle parse error
      }
    }

    // Parse date for proper formatting: "พ. 13" and "ธ.ค. 68"
    String dayLine = '';
    String dateLine = '';
    _parseThaiDate(item.CREATE_DATE_TH, (day, date) {
      dayLine = day;
      dateLine = date;
    });

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Column - "พ. 13\nธ.ค. 68" format
          Container(
            width: 45,
            padding: EdgeInsets.only(right: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayLine,
                  style: GoogleFonts.kanit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  dateLine,
                  style: GoogleFonts.kanit(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          // Check-in Column
          Expanded(
            child: GestureDetector(
              onTap: () => _showImagePopup(context, index, 1),
              child: Row(
                children: [
                  // Square Image with rounded corners
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 55,
                      height: 55,
                      color: Colors.grey[200],
                      child: item.START_IMAGE_SMALL.isNotEmpty
                          ? Image.network(
                              Server.url + item.START_IMAGE_SMALL,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                color: Colors.grey,
                              ),
                            )
                          : Icon(Icons.person, color: Colors.grey),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/other/checkin_clock.png',
                              width: 16,
                              height: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'เข้างาน',
                              style: GoogleFonts.kanit(
                                fontSize: 12,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          item.START_TIME.isNotEmpty
                              ? '${item.START_TIME}${isLate ? " (สาย)" : ""}'
                              : '-',
                          style: GoogleFonts.kanit(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isLate ? Colors.orange : Colors.black87,
                          ),
                        ),
                        if (isOutside && outsideDetails.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(top: 2),
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Color(0xFFE1BEE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              outsideDetails[0].TOPIC,
                              style: GoogleFonts.kanit(
                                fontSize: 11,
                                color: Colors.purple[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (item.START_LOCATION_STATUS == '1')
                          Text(
                            'อยู่นอกพื้นที่ : ใช่',
                            style: GoogleFonts.kanit(
                              fontSize: 10,
                              color: Colors.cyan,
                            ),
                          ),
                        if (item.START_ADDRESS.isNotEmpty)
                          GestureDetector(
                            onTap: () async {
                              if (item.START_LATITUDE.isNotEmpty &&
                                  item.START_LONGITUDE.isNotEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return MapViewerPopup(
                                      lat: double.parse(item.START_LATITUDE),
                                      long: double.parse(item.START_LONGITUDE),
                                      title: 'สถานที่เข้างาน',
                                      address: item.START_ADDRESS,
                                    );
                                  },
                                );
                              }
                            },
                            child: Container(
                              margin: EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.locationDot,
                                    size: 12,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      item.START_ADDRESS,
                                      style: GoogleFonts.kanit(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  )
                                ],
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

          // Check-out Column
          Expanded(
            child: GestureDetector(
              onTap: () => _showImagePopup(context, index, 2),
              child: Row(
                children: [
                  // Square Image with rounded corners
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 55,
                      height: 55,
                      color: Colors.grey[200],
                      child: item.END_IMAGE_SMALL.isNotEmpty
                          ? Image.network(
                              Server.url + item.END_IMAGE_SMALL,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                color: Colors.grey,
                              ),
                            )
                          : Icon(Icons.person, color: Colors.grey),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/other/checkout_clock.png',
                              width: 16,
                              height: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'ออกงาน',
                              style: GoogleFonts.kanit(
                                fontSize: 12,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          item.END_TIME.isNotEmpty ? item.END_TIME : '-',
                          style: GoogleFonts.kanit(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        if (item.END_LOCATION_STATUS == '1' || item.CID == '3')
                          Text(
                            'อยู่นอกพื้นที่ : ใช่',
                            style: GoogleFonts.kanit(
                              fontSize: 10,
                              color: Colors.cyan,
                            ),
                          ),
                        if (item.END_ADDRESS.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              if (item.END_LATITUDE.isNotEmpty &&
                                  item.END_LONGITUDE.isNotEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return MapViewerPopup(
                                      lat: double.parse(item.END_LATITUDE),
                                      long: double.parse(item.END_LONGITUDE),
                                      title: 'สถานที่ออกงาน',
                                      address: item.END_ADDRESS,
                                    );
                                  },
                                );
                              }
                            },
                            child: Container(
                              margin: EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.locationDot,
                                    size: 12,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      item.END_ADDRESS,
                                      style: GoogleFonts.kanit(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  )
                                ],
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
        ],
      ),
    );
  }

  void _parseThaiDate(String dateStr, Function(String, String) callback) {
    // Input format examples: "จ. 15 ธ.ค. 68" or "15 ธ.ค. 68"
    // Output: "พ. 13" and "ธ.ค. 68"
    try {
      var parts = dateStr.split(' ');
      if (parts.length >= 3) {
        String dayAbbr = parts[0]; // "จ." or "พ."
        String dayNum = parts[1]; // "15"
        String monthYear = '${parts[2]} ${parts.length > 3 ? parts[3] : ""}';
        callback('$dayAbbr $dayNum', monthYear.trim());
      } else if (parts.length == 2) {
        callback(parts[0], parts[1]);
      } else {
        callback(dateStr, '');
      }
    } catch (e) {
      callback(dateStr, '');
    }
  }

  void _showImagePopup(BuildContext context, int index, int status) {
    final item = _result[index];
    String imageUrl = status == 1 ? item.START_IMAGE : item.END_IMAGE;
    String dateTh = item.CREATE_DATE_TH;
    String time = status == 1 ? item.START_TIME : item.END_TIME;
    String lat = status == 1 ? item.START_LATITUDE : '';
    String long = status == 1 ? item.START_LONGITUDE : '';

    showDialog(
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
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            Server.url + imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: Icon(Icons.broken_image, size: 50),
                            ),
                          )
                        : Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: Icon(Icons.image, size: 50),
                          ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'วันที่ $dateTh เวลา $time',
                        style: GoogleFonts.kanit(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      if (lat.isNotEmpty && long.isNotEmpty)
                        GestureDetector(
                          onTap: () async {
                            String url =
                                'https://www.google.com/maps/search/?api=1&query=$lat,$long';
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(FontAwesomeIcons.locationDot,
                                    size: 14, color: Colors.grey[600]),
                                SizedBox(width: 6),
                                Text(
                                  'ดูสถานที่',
                                  style: GoogleFonts.kanit(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            'ปิด',
                            style: GoogleFonts.kanit(
                              fontSize: 14,
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
}

class MapViewerPopup extends StatefulWidget {
  final double lat;
  final double long;
  final String title;
  final String address;

  const MapViewerPopup({
    Key? key,
    required this.lat,
    required this.long,
    required this.title,
    required this.address,
  }) : super(key: key);

  @override
  _MapViewerPopupState createState() => _MapViewerPopupState();
}

class _MapViewerPopupState extends State<MapViewerPopup> {
  Completer<GoogleMapController> _controller = Completer();

  @override
  Widget build(BuildContext context) {
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
            // Map Header
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(widget.lat, widget.long),
                    zoom: 16,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId('target'),
                      position: LatLng(widget.lat, widget.long),
                      infoWindow: InfoWindow(title: widget.title),
                    ),
                  },
                  myLocationEnabled: false,
                  zoomControlsEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                ),
              ),
            ),

            // Address Info
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: GoogleFonts.kanit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.address,
                      style: GoogleFonts.kanit(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              'ปิด',
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            String url =
                                'https://www.google.com/maps/search/?api=1&query=${widget.lat},${widget.long}';
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Color(0xFF21CCD4),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              'เปิดใน Google Maps',
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum LongdoMapMode { picker, route }

class LongdoMapPage extends StatefulWidget {
  final double lat;
  final double lon;
  final double? endLat;
  final double? endLon;
  final String? startAddress; // Optional label for start marker
  final String? endAddress; // Optional label for end marker
  final LongdoMapMode mode;

  const LongdoMapPage({
    Key? key,
    required this.lat,
    required this.lon,
    this.endLat,
    this.endLon,
    this.startAddress,
    this.endAddress,
    this.mode = LongdoMapMode.picker,
  }) : super(key: key);

  @override
  State<LongdoMapPage> createState() => _LongdoMapPageState();
}

class _LongdoMapPageState extends State<LongdoMapPage> {
  late final WebViewController _controller;
  final String _apiKey = "2e66f91813f7912cf50d419f3e5e3dea";

  String _currentAddress = "Loading...";
  double _selectedLat = 0.0;
  double _selectedLon = 0.0;

  // Route details
  String _distance = "-";
  String _duration = "-";

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.lat;
    _selectedLon = widget.lon;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            var data = jsonDecode(message.message);

            // Handle Route Result
            if (data['action'] == 'route_result') {
              blocSetState(() {
                _distance = "${data['distance_km']} km";
                _duration = "${data['duration_min']} min";
              });
              return;
            }

            // Handle Address Result
            blocSetState(() {
              if (data['address'] != null) {
                _currentAddress = data['address'];
              }
              if (data['lat'] != null) _selectedLat = data['lat'];
              if (data['lon'] != null) _selectedLon = data['lon'];
            });
          } catch (e) {
            // Fallback
            blocSetState(() {
              _currentAddress = message.message;
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (String url) {}),
      )
      ..loadHtmlString(_buildHtmlContent());
  }

  String _buildHtmlContent() {
    bool isRoute = widget.mode == LongdoMapMode.route;

    // Safety check for end coords
    double endLat = widget.endLat ?? widget.lat;
    double endLon = widget.endLon ?? widget.lon;

    String startTitle = widget.startAddress ?? 'Selected Location';
    String endTitle = widget.endAddress ?? 'Destination';

    return '''
      <!DOCTYPE HTML>
      <html>
      <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { margin: 0; padding: 0; height: 100vh; width: 100vw; font-family: sans-serif; }
        #map { height: 100%; width: 100%; }
      </style>
      <script src="https://api.longdo.com/map/?key=$_apiKey"></script>
      <script>
        var map;
        var marker;
        var mode = "${isRoute ? 'route' : 'picker'}";
        
        function init() {
          map = new longdo.Map({
            placeholder: document.getElementById('map')
          });
          
          var startLoc = { lon: ${widget.lon}, lat: ${widget.lat} };
          var endLoc = { lon: $endLon, lat: $endLat };

          // Center map
          map.location(startLoc);
          map.zoom(15);
          
          if (mode === 'route') {
            // Draw Route
            map.Route.add(startLoc);
            map.Route.add(endLoc);
            map.Route.search();
            
            // Add Markers with Labels
            map.Overlays.add(new longdo.Marker(startLoc, { title: '$startTitle', detail: 'Start' }));
            map.Overlays.add(new longdo.Marker(endLoc, { title: '$endTitle', detail: 'End' }));
            
            // Auto Zoom to fit
            // Note: simple zoom for now, Longdo doesn't have autoFitBounds easily without calc
            
            // Listen for route calculation
            map.Event.bind('route', function(result) {
              if (result) {
                var distKm = (result.distance / 1000).toFixed(2);
                var mins = Math.ceil(result.duration / 60);
                
                var data = {
                  "action": "route_result",
                  "distance_km": distKm,
                  "duration_min": mins
                };
                Toaster.postMessage(JSON.stringify(data));
              }
            });

          } else {
            // Picker Mode
            marker = new longdo.Marker(startLoc, {
              title: 'Start Location',
              detail: 'Drag me or click map'
            });
            map.Overlays.add(marker);
            
            // Initial Reverse Geocode
            getAddress(startLoc.lon, startLoc.lat);

            // Click to move
            map.Event.bind('click', function(overlay) {
               var loc = map.location('POINTER');
               moveMarker(loc);
            });
          }
        }

        function moveMarker(loc) {
          map.Overlays.remove(marker);
          marker = new longdo.Marker(loc);
          map.Overlays.add(marker);
          getAddress(loc.lon, loc.lat);
        }

        function getAddress(lon, lat) {
           longdo.Service.address(
             { lon: lon, lat: lat },
             function(result) {
                if (result) {
                  // Replicate LongdoMapService.fullAddress logic
                  var parts = [];
                  
                  // AOI
                  if (result.aoi) parts.push(result.aoi);
                  
                  // Road
                  if (result.road) {
                    var r = result.road;
                    if (!r.startsWith('ถ.') && !r.startsWith('ถนน')) r = 'ถ.' + r;
                    parts.push(r);
                  }
                  
                  // Subdistrict
                  if (result.subdistrict) {
                    var s = result.subdistrict;
                    if (!s.startsWith('ต.') && !s.startsWith('ตำบล') && !s.startsWith('แขวง')) s = 'ต.' + s;
                    parts.push(s);
                  }
                  
                  // District
                  if (result.district) {
                    var d = result.district;
                    if (!d.startsWith('อ.') && !d.startsWith('อำเภอ') && !d.startsWith('เขต')) d = 'อ.' + d;
                    parts.push(d);
                  }
                  
                  // Province
                  if (result.province) {
                    var p = result.province;
                    if (!p.startsWith('จ.') && !p.startsWith('จังหวัด') && p !== 'กรุงเทพมหานคร') p = 'จ.' + p;
                    parts.push(p);
                  }
                  
                  // Postcode
                  if (result.postcode) parts.push(result.postcode);
                  
                  var addr = parts.join(' ');
                  if (addr.trim() === '') addr = 'ไม่พบข้อมูลที่อยู่';
                  
                  var data = {
                    "address": addr.trim(),
                    // COMPATIBILITY: alias start_address for other project
                    "start_address": addr.trim(), 
                    "lat": lat,
                    "lon": lon
                  };
                  Toaster.postMessage(JSON.stringify(data));
                }
             },
             function(error) {
                // error
             }
           );
        }
      </script>
      </head>
      <body onload="init();">
        <div id="map"></div>
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    bool isRoute = widget.mode == LongdoMapMode.route;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRoute ? "Route Preview" : "Pick Location"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (!isRoute)
            IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                Navigator.of(context).pop({
                  "address": _currentAddress,
                  "start_address": _currentAddress,
                  "lat": _selectedLat,
                  "lon": _selectedLon,
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: WebViewWidget(controller: _controller)),
          if (!isRoute)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selected Address:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(_currentAddress, style: TextStyle(fontSize: 16)),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop({
                          "address": _currentAddress,
                          "start_address": _currentAddress,
                          "lat": _selectedLat,
                          "lon": _selectedLon,
                        });
                      },
                      child: Text(
                        "Confirm Location",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (isRoute)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Icon(Icons.directions_car, color: Colors.blue),
                      Text("Distance", style: TextStyle(color: Colors.grey)),
                      Text(
                        _distance,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.access_time, color: Colors.orange),
                      Text("Duration", style: TextStyle(color: Colors.grey)),
                      Text(
                        _duration,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class LongdoMapService {
  static const String _apiKey = "2e66f91813f7912cf50d419f3e5e3dea";
  static const String _baseUrl = "https://api.longdo.com/map/services/address";

  Future<String?> getFormattedAddress(double lat, double lon) async {
    try {
      final Uri uri = Uri.parse("$_baseUrl?lon=$lon&lat=$lat&key=$_apiKey");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));

        // Example Response:
        // {
        //   "geocode": "100103",
        //   "province": "กรุงเทพมหานคร",
        //   "district": "เขตพระนคร",
        //   "subdistrict": "แขวงพระบรมมหาราชวัง",
        //   "postcode": "10200",
        //   "elevation": 4,
        //   "road": "ถนนหน้าพระลาน",
        //   "aoi": "วัดพระศรีรัตนศาสดาราม"
        // }

        if (decoded is Map<String, dynamic>) {
          List<String> parts = [];

          // Aoi (Area of Interest - e.g., Landmark)
          if (decoded['aoi'] != null && decoded['aoi'].toString().isNotEmpty) {
            parts.push(decoded['aoi']);
          }

          // Road
          if (decoded['road'] != null &&
              decoded['road'].toString().isNotEmpty) {
            String r = decoded['road'];
            if (!r.startsWith('ถ.') && !r.startsWith('ถนน')) r = 'ถ.$r';
            parts.push(r);
          }

          // Subdistrict
          if (decoded['subdistrict'] != null &&
              decoded['subdistrict'].toString().isNotEmpty) {
            String s = decoded['subdistrict'];
            bool isBkk = decoded['province'].toString().contains('กรุงเทพ');
            if (!s.startsWith(isBkk ? 'แขวง' : 'ต.') && !s.startsWith('ตำบล')) {
              s = (isBkk ? 'แขวง' : 'ต.') + s;
            }
            parts.push(s);
          }

          // District
          if (decoded['district'] != null &&
              decoded['district'].toString().isNotEmpty) {
            String d = decoded['district'];
            bool isBkk = decoded['province'].toString().contains('กรุงเทพ');
            if (!d.startsWith(isBkk ? 'เขต' : 'อ.') && !d.startsWith('อำเภอ')) {
              d = (isBkk ? 'เขต' : 'อ.') + d;
            }
            parts.push(d);
          }

          // Province
          if (decoded['province'] != null &&
              decoded['province'].toString().isNotEmpty) {
            String p = decoded['province'];
            if (!p.startsWith('จ.') &&
                !p.startsWith('จังหวัด') &&
                !p.contains('กรุงเทพ')) {
              p = 'จ.' + p;
            }
            parts.push(p);
          }

          if (decoded['postcode'] != null &&
              decoded['postcode'].toString().isNotEmpty) {
            parts.push(decoded['postcode']);
          }

          return parts.isNotEmpty ? parts.join(' ') : null;
        }
      }
      return null;
    } catch (e) {
      print("LongdoMapService Error: $e");
      return null;
    }
  }
}

extension ListExt<E> on List<E> {
  void push(E element) => this.add(element);
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ismart_login/src/features/managements/presentation/pages/model/itemOrgManage.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/model/itemOrgResultManage.dart';
import 'package:ismart_login/server/server.dart';

final Map<String, String> header = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*", // Required for CORS support to work
  "Access-Control-Allow-Credentials": "true",
  "Access-Control-Allow-Headers":
      "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
  "Access-Control-Allow-Methods": "*"
};

class OrgManageFuture {
  OrgManageFuture() : super();
  //---
  Future<List<ItemsOrgPostManage>> apiPostOrgManageList(Map jsonMap) async {
    //encode Map to JSON
    var body = json.encode(jsonMap);
    final response = await http.post(
      Uri.parse(Server().postOrg),
      headers: header,
      body: body,
    );
    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      return responseJson
          .map((m) => new ItemsOrgPostManage.fromJson(m))
          .toList();
    } else {
      print('Something went wrong. \nResponse Code : ${response.statusCode}');
      throw Exception('Failed to load organization management list');
    }
  }

  Future<List<ItemsOrgGetManage>> apiGetOrgManageList(Map jsonMap) async {
    //encode Map to JSON
    var body = json.encode(jsonMap);
    final response = await http.post(
      Uri.parse(Server().getOrgAdmin),
      headers: header,
      body: body,
    );
    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      return responseJson
          .map((m) => new ItemsOrgGetManage.fromJson(m))
          .toList();
    } else {
      print('Something went wrong. \nResponse Code : ${response.statusCode}');
      throw Exception('Failed to load organization management list');
    }
  }

  Future<List<ItemsOrgSuspendManage>> apiUpdateSuspendOrgManageList(
      Map jsonMap) async {
    //encode Map to JSON
    var body = json.encode(jsonMap);
    final response = await http.post(
      Uri.parse(Server().updateOrgSuspend),
      headers: header,
      body: body,
    );
    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      return responseJson
          .map((m) => new ItemsOrgSuspendManage.fromJson(m))
          .toList();
    } else {
      print('Something went wrong. \nResponse Code : ${response.statusCode}');
      throw Exception('Failed to update suspend organization management list');
    }
  }

  Future<List<ItemsOrgResultManage>> apiGetPublicOrg(Map jsonMap) async {
    var body = json.encode(jsonMap);
    final response = await http.post(
      Uri.parse(Server().getOrg),
      headers: header,
      body: body,
    );
    if (response.statusCode == 200) {
      // The public API returns: [{"msg":"success", "result": [ {...fields...} ] }]
      // or [{"msg":"fail", "result": []}]
      // We need to map this to ItemsOrgResultManage structure
      List responseJson = json.decode(response.body);
      if (responseJson.isNotEmpty && responseJson[0]['result'] != null) {
        List resultList = responseJson[0]['result'];
        if (resultList.isEmpty) return [];

        return resultList.map((m) {
          // Map org_information fields to ItemsOrgResultManage expectation
          return ItemsOrgResultManage(
            ID: (m['id'] ?? '').toString(),
            ORG_ID: (m['id'] ?? '').toString(),
            SUBJECT: m['subject'] ?? '',
            CREATE_BY: '0',
            ACTIVE: true,
            ORG_CREATE: m['create_date'] ?? '',
            INVITE: m['invite_code'] ?? '',
            HISTORY: m['history_status'] ?? '0',
            NOTI: m['noti_status'] ?? '0',
            OT: m['ot_status'] ?? '0',
            LOGUT_STATUS: m['logout_status'] ?? '0',
            TIME_STATUS: m['time_status'] ?? '0',
            LEAVE_CANCEL_STATUS: m['leave_cancel_status'] ?? '0',
          );
        }).toList();
      }
      return [];
    } else {
      throw Exception('Failed to load public organization');
    }
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:ismart_login/utils/dialog_helper.dart';
import 'package:ismart_login/page/profile/model/itemPasswordResult.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/system/shared_preferences.dart';

final Map<String, String> header = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*", // Required for CORS support to work
  "Access-Control-Allow-Credentials": "true",
  "Access-Control-Allow-Headers":
      "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
  "Access-Control-Allow-Methods": "*"
};

class ProfileFuture {
  Future<dynamic> updateProfile({
    required BuildContext context,
    required String file,
    String? uid,
    String? name,
    String? lastname,
    String? nickname,
    String? department,
    String? time,
    String? org_id,
  }) async {
    AwesomeDialog loadingDialog =
        DialogHelper.showLoading(context, 'กำลังอัพโหลด...');
    String fileName = file.split('/').last;
    var formData = FormData.fromMap({
      "file": file != ''
          ? await MultipartFile.fromFile(file, filename: fileName)
          : '',
      "name": name,
      "lastname": lastname,
      "nickname": nickname,
      "uid": uid,
      "department": department,
      "time": time,
      "org_id": org_id,
    });
    try {
      Response response = await Dio().post(Server().updateMember,
          data: formData, onSendProgress: (int bytes, int total) {
        // print('progress: $total ($bytes/$total) => ' + (bytes / total).toString() + '%');
        // DialogHelper doesn't support progress update easily, just show spinner
      });
      if (response.statusCode == 200) {
        print(json.encode(response.data));
        var list = json.decode(response.data);
        print(list[0]['path']);
        if (list[0]['path'] != '') {
          await SharedCashe.savaItemsString(
              key: 'avatar', valString: list[0]['path']);
        }
        if (time != "") {
          await SharedCashe.savaItemsString(
              key: 'time_id', valString: time ?? '');
        }
        loadingDialog.dismiss();
        DialogHelper.showSuccess(context, 'บันทึกเรียบร้อย');
      } else {
        loadingDialog.dismiss();
        DialogHelper.showError(context, 'เกิดข้อผิดพลาด',
            'Error : ' + response.statusCode.toString());
      }
    } catch (e) {
      loadingDialog.dismiss();
      DialogHelper.showError(context, 'เกิดข้อผิดพลาด', e.toString());
    }
  }

  Future<List<ItemsPasswordMemberResult>> apiUpdatePasswordMemberList(
      Map jsonMap) async {
    //encode Map to JSON
    var body = json.encode(jsonMap);
    final response = await http.post(
      Uri.parse(Server().updateMemberPassword),
      headers: header,
      body: body,
    );
    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      return responseJson
          .map((m) => new ItemsPasswordMemberResult.fromJson(m))
          .toList();
    } else {
      print('Something went wrong. \nResponse Code : ${response.statusCode}');
      throw Exception('Failed to update password member list');
    }
  }
}

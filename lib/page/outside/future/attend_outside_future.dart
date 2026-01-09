import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:ismart_login/page/outside/model/attendOutsideEnd.dart';
import 'package:ismart_login/page/outside/model/attendOutsideStart.dart';
import 'package:ismart_login/page/outside/model/attendOutsideToDay.dart';
import 'package:ismart_login/utils/dialog_helper.dart';

import 'package:ismart_login/server/server.dart';

class AttandOutsideFuture {
  final Map<String, String> header = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*", // Required for CORS support to work
    "Access-Control-Allow-Credentials": "true",
    "Access-Control-Allow-Headers":
        "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
    "Access-Control-Allow-Methods": "*"
  };
  AttandOutsideFuture() : super();

  Future<List<ItemsAttandOutsideToDay>> apiGetAttandOutsideCheck(
      Map jsonMap) async {
    //encode Map to JSON
    var body = json.encode(jsonMap);
    final response = await http.post(
      Uri.parse(Server().getAttandCheckOutside),
      headers: header,
      body: body,
    );
    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      return responseJson
          .map((m) => new ItemsAttandOutsideToDay.fromJson(m))
          .toList();
    } else {
      print('Something went wrong. \nResponse Code : ${response.statusCode}');
      throw Exception('Failed to load attendance data');
    }
  }

  ///---
  Future<List<ItemsAttandOutsideStartResult>> apiPostAttandOutsideStart(
      Map jsonMap) async {
    //encode Map to JSON
    var body = json.encode(jsonMap);
    final response = await http.post(
      Uri.parse(Server().postAttandOutsideStart),
      headers: header,
      body: body,
    );
    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      print(response.body);
      return responseJson
          .map((m) => new ItemsAttandOutsideStartResult.fromJson(m))
          .toList();
    } else {
      print('Something went wrong. \nResponse Code : ${response.statusCode}');
      throw Exception('Failed to post attendance start');
    }
  }

  Future<List<ItemsAttendOutsideEndResult>> apiPostAttendOutsideEnd(
      Map jsonMap) async {
    //encode Map to JSON
    var body = json.encode(jsonMap);
    final response = await http.post(
      Uri.parse(Server().postAttandOutsideEnd),
      headers: header,
      body: body,
    );
    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      return responseJson
          .map((m) => new ItemsAttendOutsideEndResult.fromJson(m))
          .toList();
    } else {
      print('Something went wrong. \nResponse Code : ${response.statusCode}');
      throw Exception('Failed to post attendance end');
    }
  }

  ///---UPLOAD
  ///---UPLOAD
  Future<dynamic> uploadAttendOutside({
    required BuildContext context,
    required File file,
    required String uploadKey,
    required String uid,
    required String cmd,
    required String attact_type,
  }) async {
    AwesomeDialog? loadingDialog =
        DialogHelper.showLoading(context, "กำลังอัพโหลด");
    try {
      String fileName = file.path.split('/').last;
      var formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
        "uploadKey": uploadKey,
        "uid": uid,
        "cmd": cmd,
        "attact_type": attact_type,
      });

      Response response = await Dio().post(
        Server().postAttandUploadImages,
        data: formData,
        onSendProgress: (int bytes, int total) {
          double progress = bytes / total;
          print('progress: $total ($bytes/$total) => ' +
              progress.toString() +
              '%');
          // Note: AwesomeDialog doesn't support progress update easily.
        },
      );

      loadingDialog.dismiss();
      print(json.encode(response.data));
      DialogHelper.showSuccess(context, 'เรียบร้อย');
      return response.data;
    } catch (e) {
      loadingDialog.dismiss();
      print('Error uploading: $e');
      DialogHelper.showError(context, 'อัพโหลดล้มเหลว', e.toString());
    }
  }

  //----------------
}

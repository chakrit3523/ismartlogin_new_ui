import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:ismart_login/src/features/sign/presentation/pages/model/checkmemberlist.dart';
import 'package:ismart_login/src/features/sign/presentation/pages/model/for_post.dart';
import 'package:ismart_login/src/features/sign/presentation/pages/model/otplist.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/utils/dialog_helper.dart';

final Map<String, String> header = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*", // Required for CORS support to work
  "Access-Control-Allow-Credentials": "true",
  "Access-Control-Allow-Headers":
      "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
  "Access-Control-Allow-Methods": "*"
};

class MemberFuture {
  MemberFuture() : super();

  /// Check if a member exists by email (for social login)
  /// Returns member data if exists, empty list if not
  Future<List<ItemsCheckMemberResult>> apiCheckMemberByEmail(
      String email) async {
    var body = json.encode({"email": email});
    final response = await http.post(
      Uri.parse(Server().checkMemberByEmail), // New endpoint for email check
      headers: header,
      body: body,
    );
    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      return responseJson
          .map((m) => ItemsCheckMemberResult.fromJson(m))
          .toList();
    } else {
      return []; // Return empty if not found
    }
  }

//-----
  Future<List<ItemsCheckMemberResult>> apiGetCheckMember(Map jsonMap) async {
    //encode Map to JSON
    var body = json.encode(jsonMap);
    final response = await http.post(
      Uri.parse(Server().getCheckMember),
      headers: header,
      body: body,
    );
    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      return responseJson
          .map((m) => new ItemsCheckMemberResult.fromJson(m))
          .toList();
    } else {
      print('Something went wrong. \nResponse Code : ${response.statusCode}');
      throw Exception('Failed to load check member');
    }
  }

  Future<List<ItemsMemberResultList>> apiInsertMember(Map jsonMap) async {
    //encode Map to JSON
    var body = json.encode(jsonMap);
    final response = await http.post(
      Uri.parse(Server().postMember),
      headers: header,
      body: body,
    );
    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      return responseJson
          .map((m) => new ItemsMemberResultList.fromJson(m))
          .toList();
    } else {
      print('Something went wrong. \nResponse Code : ${response.statusCode}');
      throw Exception('Failed to insert member');
    }
  }

  //-----
  //----OTP
  Future<List<ItemsOTPList>> apiPostOtp(Map jsonMap) async {
    //encode Map to JSON
    var body = json.encode(jsonMap);
    final response = await http.post(
      Uri.parse(Server().postOtp),
      headers: header,
      body: body,
    );
    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      return responseJson.map((m) => new ItemsOTPList.fromJson(m)).toList();
    } else {
      print('Something went wrong. \nResponse Code : ${response.statusCode}');
      throw Exception('Failed to post OTP');
    }
  }

  Future<List<ItemsOTPList>> apiGetCheckOtp(Map jsonMap) async {
    //encode Map to JSON
    var body = json.encode(jsonMap);
    final response = await http.post(
      Uri.parse(Server().getCheckOtp),
      headers: header,
      body: body,
    );
    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      return responseJson.map((m) => new ItemsOTPList.fromJson(m)).toList();
    } else {
      print('Something went wrong. \nResponse Code : ${response.statusCode}');
      throw Exception('Failed to check OTP');
    }
  }

  Future<dynamic> uploadAvatarProfile({
    required BuildContext context,
    required String file,
    required String uploadKey,
  }) async {
    String fileName = file.split('/').last;
    var formData = FormData.fromMap({
      "file": file != ''
          ? await MultipartFile.fromFile(file, filename: fileName)
          : '',
      "uploadKey": uploadKey,
    });

    // Show loading dialog
    AwesomeDialog loadingDialog =
        DialogHelper.showLoading(context, "กำลังอัพโหลด...");

    try {
      Response response = await Dio().post(
        Server().postAvatarMember,
        data: formData,
        // Note: Progress update removed as AwesomeDialog doesn't support it natively in this simple helper.
        // If we really need progress, we'd need a StatefulBuilder in DialogHelper.
      );

      loadingDialog.dismiss();

      if (response.statusCode == 200) {
        print(json.encode(response.data));
        // var list = json.decode(response.data); // Decode loop might fail if response.data is already map/list
        // print("ผลการอัพโหลดรูป : " + list[0]['result']);
        DialogHelper.showSuccess(context, 'อัพโหลดเรียบร้อย');
      }
    } catch (e) {
      loadingDialog.dismiss();
      DialogHelper.showError(
          context, 'อัพโหลดล้มเหลว', 'เกิดข้อผิดพลาด: ${e.toString()}');
    }
  }
}

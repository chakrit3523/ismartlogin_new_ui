import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:ismart_login/src/features/front/presentation/pages/model/attendEnd.dart';
import 'package:ismart_login/src/features/front/presentation/pages/model/attendHistory.dart';
import 'package:ismart_login/src/features/front/presentation/pages/model/attendStart.dart';
import 'package:ismart_login/src/features/front/presentation/pages/model/attendToDay.dart';
import 'package:ismart_login/src/features/front/presentation/pages/model/attendUpdateStart.dart';
import 'package:ismart_login/utils/dialog_helper.dart';

import 'package:ismart_login/server/server.dart';

class AttandFuture {
  final Map<String, String> header = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*", // Required for CORS support to work
    "Access-Control-Allow-Credentials": "true",
    "Access-Control-Allow-Headers":
        "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
    "Access-Control-Allow-Methods": "*"
  };
  AttandFuture() : super();

  Future<List<ItemsAttandToDay>> apiGetAttandCheck(Map jsonMap) async {
    //encode Map to JSON
    var body = json.encode(jsonMap);
    print('--- apiGetAttandCheck ---');
    print(body);
    final response = await http.post(
      Uri.parse(Server().getAttandCheck),
      headers: header,
      body: body,
    );
    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      return responseJson.map((m) => new ItemsAttandToDay.fromJson(m)).toList();
    } else {
      print('Something went wrong. \nResponse Code : ${response.statusCode}');
      throw Exception('Failed to load attendance check');
    }
  }

  ///---
  Future<List<ItemsAttandStartResult>> apiPostAttandStart(Map jsonMap) async {
    //encode Map to JSON
    var body = json.encode(jsonMap);
    final response = await http.post(
      Uri.parse(Server().postAttandStart),
      headers: header,
      body: body,
    );
    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      print(response.body);
      return responseJson
          .map((m) => new ItemsAttandStartResult.fromJson(m))
          .toList();
    } else {
      print('Something went wrong. \nResponse Code : ${response.statusCode}');
      throw Exception('Failed to post attendance start');
    }
  }

  Future<List<ItemsUpdateAttandStartResult>> apiUpdateAttandStart(
      Map jsonMap) async {
    //encode Map to JSON
    var body = json.encode(jsonMap);
    final response = await http.post(
      Uri.parse(Server().updateAttandStart),
      headers: header,
      body: body,
    );
    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      return responseJson
          .map((m) => new ItemsUpdateAttandStartResult.fromJson(m))
          .toList();
    } else {
      print('Something went wrong. \nResponse Code : ${response.statusCode}');
      throw Exception('Failed to update attendance start');
    }
  }

  Future<List<ItemsAttendEndResult>> apiPostAttendEnd(Map jsonMap) async {
    //encode Map to JSON
    var body = json.encode(jsonMap);
    final response = await http.post(
      Uri.parse(Server().postAttandEnd),
      headers: header,
      body: body,
    );
    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      return responseJson
          .map((m) => new ItemsAttendEndResult.fromJson(m))
          .toList();
    } else {
      print('Something went wrong. \nResponse Code : ${response.statusCode}');
      throw Exception('Failed to post attendance end');
    }
  }

  ///---UPLOAD
  /// Upload attendance image
  ///
  /// Returns Map with upload result:
  /// - 'success': true/false
  /// - 'uploadKey': the uploadKey used
  /// - 'error': error message if failed
  ///---UPLOAD
  /// Upload attendance image
  ///
  /// Returns Map with upload result:
  /// - 'success': true/false
  /// - 'uploadKey': the uploadKey used
  /// - 'error': error message if failed
  Future<Map<String, dynamic>> uploadAttend({
    required BuildContext context,
    required File file,
    required String uploadKey,
    required String uid,
    required String cmd,
    required String attact_type,
    Function(double)? onProgress,
  }) async {
    // Show loading dialog if no custom progress callback is provided (or even if it is, consistent UI)
    // AwesomeDialog doesn't support progress updates easily.
    // We will use a simple loading dialog.
    AwesomeDialog? loadingDialog;
    if (onProgress == null) {
      loadingDialog = DialogHelper.showLoading(context, "กำลังอัพโหลด...");
    }

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
          print(
              'Upload progress: ${(progress * 100).toStringAsFixed(1)}% ($bytes/$total bytes)');

          if (onProgress != null) {
            onProgress(progress);
          }
        },
      );

      if (loadingDialog != null) loadingDialog.dismiss();

      print('Upload response: ${json.encode(response.data)}');

      // Check if upload was successful
      if (response.statusCode == 200) {
        return {
          'success': true,
          'uploadKey': uploadKey,
          'response': response.data,
        };
      } else {
        return {
          'success': false,
          'uploadKey': uploadKey,
          'error': 'Upload failed with status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      if (loadingDialog != null) loadingDialog.dismiss();
      print('Error uploading attendance image: $e');
      return {
        'success': false,
        'uploadKey': uploadKey,
        'error': e.toString(),
      };
    }
  }

  //----------------
  //-----------------
  Future<List<ItemsAttendHistory>> apiGetAttendHistory(Map jsonMap) async {
    //encode Map to JSON
    var body = json.encode(jsonMap);
    final response = await http.post(
      Uri.parse(Server().getAttandHistory),
      headers: header,
      body: body,
    );
    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      return responseJson
          .map((m) => new ItemsAttendHistory.fromJson(m))
          .toList();
    } else {
      print('Something went wrong. \nResponse Code : ${response.statusCode}');
      throw Exception('Failed to load attendance history');
    }
  }

  // ============================================================
  // V2 API Methods - 2-Step Synchronous Upload
  // Step 1: uploadImageV2 - Upload image only, get uploadKey
  // Step 2: apiPostAttandStartV2/apiPostAttendEndV2 - Submit attendance
  // ============================================================

  /// V2: Upload image first, returns uploadKey
  ///
  /// Returns Map with:
  /// - 'success': true/false
  /// - 'uploadKey': the generated uploadKey
  /// - 'imagePath': path of uploaded file
  /// - 'error': error message if failed
  Future<Map<String, dynamic>> uploadImageV2({
    required BuildContext context,
    required File file,
    required String uid,
    required String attactType, // 'i_start' for check-in, 'i_end' for check-out
    Function(double)? onProgress,
  }) async {
    AwesomeDialog? loadingDialog;
    if (onProgress == null) {
      loadingDialog = DialogHelper.showLoading(context, "กำลังอัพโหลดภาพ...");
    }

    try {
      String fileName = file.path.split('/').last;
      var formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
        "uid": uid,
        "attact_type": attactType,
      });

      Response response = await Dio().post(
        Server().uploadImageV2,
        data: formData,
        onSendProgress: (int bytes, int total) {
          double progress = bytes / total;
          print(
              'V2 Upload progress: ${(progress * 100).toStringAsFixed(1)}% ($bytes/$total bytes)');

          if (onProgress != null) {
            onProgress(progress);
          }
        },
      );

      if (loadingDialog != null) loadingDialog.dismiss();

      print('V2 Upload response: ${json.encode(response.data)}');

      if (response.statusCode == 200 && response.data != null) {
        // Handle response - may be String or already parsed
        var responseData = response.data;
        if (responseData is String) {
          responseData = json.decode(responseData);
        }

        // Get first item if it's a list
        final data = responseData is List ? responseData[0] : responseData;

        if (data['success'] == true) {
          return {
            'success': true,
            'uploadKey': data['uploadKey'],
            'imagePath': data['imagePath'],
            'error': null,
          };
        } else {
          return {
            'success': false,
            'uploadKey': null,
            'imagePath': null,
            'error': data['error'] ?? 'Upload failed',
          };
        }
      } else {
        return {
          'success': false,
          'uploadKey': null,
          'imagePath': null,
          'error': 'Upload failed with status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error in V2 uploadImage: $e');
      if (loadingDialog != null) loadingDialog.dismiss();
      return {
        'success': false,
        'uploadKey': null,
        'imagePath': null,
        'error': e.toString(),
      };
    }
  }

  /// V2: Check-In with pre-uploaded uploadKey
  Future<Map<String, dynamic>> apiPostAttandStartV2(Map jsonMap) async {
    var body = json.encode(jsonMap);
    print('V2 AttendStart request: $body');

    final response = await http.post(
      Uri.parse(Server().attendStartV2),
      headers: header,
      body: body,
    );

    print('V2 AttendStart response: ${response.body}');

    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      final data = responseJson.isNotEmpty ? responseJson[0] : null;
      if (data != null && data['status'] == 'success') {
        return {
          'success': true,
          'uid': data['uid'],
          'uploadKey': data['uploadKey'],
          'msg': data['msg'],
        };
      } else {
        return {
          'success': false,
          'uid': data?['uid'],
          'uploadKey': data?['uploadKey'],
          'msg': data?['msg'] ?? 'Unknown error',
        };
      }
    } else {
      print('V2 AttendStart failed: ${response.statusCode}');
      return {
        'success': false,
        'msg': 'Request failed with status code: ${response.statusCode}',
      };
    }
  }

  /// V2: Check-Out with pre-uploaded uploadKey
  Future<Map<String, dynamic>> apiPostAttendEndV2(Map jsonMap) async {
    var body = json.encode(jsonMap);
    print('V2 AttendEnd request: $body');

    final response = await http.post(
      Uri.parse(Server().attendEndV2),
      headers: header,
      body: body,
    );

    print('V2 AttendEnd response: ${response.body}');

    if (response.statusCode == 200) {
      List responseJson = json.decode(response.body);
      final data = responseJson.isNotEmpty ? responseJson[0] : null;
      if (data != null && data['status'] == 'success') {
        return {
          'success': true,
          'uid': data['uid'],
          'uploadKey': data['uploadKey'],
          'msg': data['msg'],
        };
      } else {
        return {
          'success': false,
          'uid': data?['uid'],
          'uploadKey': data?['uploadKey'],
          'msg': data?['msg'] ?? 'Unknown error',
        };
      }
    } else {
      print('V2 AttendEnd failed: ${response.statusCode}');
      return {
        'success': false,
        'msg': 'Request failed with status code: ${response.statusCode}',
      };
    }
  }
}

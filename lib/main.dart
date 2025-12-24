// ignore_for_file: deprecated_member_use, unnecessary_import

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:ismart_login/page/splashscreen/splashscreen_screen.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/system/FirebaseNotification.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:package_info/package_info.dart';
// import 'package:r_scan/r_scan.dart';
import 'package:rxdart/subjects.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 Handling background message: ${message.messageId}');
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject =
    BehaviorSubject<ReceivedNotification>();

final BehaviorSubject<String> selectNotificationSubject =
    BehaviorSubject<String>();

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final String payload;
}

String selectedNotificationPayload = '';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey(debugLabel: "MainNavigator"); //ให้ไปหน้านั้นได้เมื่อกดจาก noti

// List<RScanCameraDescription> rScanCameras;

AndroidNotificationChannel? channel;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ ตั้งค่า background handler ของ FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ เพิ่มส่วนนี้ (สร้างช่องแจ้งเตือน Android)
  const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
    'high_importance_channel', // id ต้องไม่ซ้ำกับ channel อื่น
    'High Importance Notifications', // ชื่อแสดงในระบบ
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(defaultChannel);

  channel = defaultChannel; // เก็บไว้ใช้ตอนแสดง notification

  // ✅ setup FCM logic (ห้ามมี onBackgroundMessage ในนี้ซ้ำ)
  await FirebaseNotification().setupInteractedMessage();

  // ✅ runApp หลังเตรียมระบบเสร็จแล้ว
  runApp(MaterialApp(
    navigatorKey: navigatorKey,
    home: const MyApp(key: Key('MainApp')),
    debugShowCheckedModeBanner: false,
  ));

  configLoading();
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = true
    ..dismissOnTap = false;
}

class MyApp extends StatefulWidget {
  const MyApp({required Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        print("FirebaseMessaging noti : $message");
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null && !kIsWeb) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel?.id ?? '',
              channel?.name ?? '',
              channelDescription: channel?.description ?? '',
              icon: 'ic_launcher',
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
    });

    //check update app
    initPackageInfo();
  }

  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  Future<void> initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _packageInfo = info;
      paramCheckAppData();
    } catch (e) {
      print("initPackageInfo error : " + e.toString());
    }
  }

  paramCheckAppData() async {
    Map _map = {};
    String platform;
    if (Platform.isIOS) {
      platform = "ios";
    } else {
      platform = "android";
    }
    _map.addAll({
      "platform": platform,
      "version": _packageInfo.version,
    });
    print("_mapVersion" + _map.toString());
    var body = json.encode(_map);
    final response = await http.Client().post(
      Uri.parse(Server().checkAppVersion),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    var data = json.decode(response.body);

    if (data["status"].toString() == "0") {
      print("_mapVersion data ${data}");
      checkAppVersion(data["msg"].toString(), data["url"].toString(),
          data["important"].toString());
    }
  }

  Future<void> checkAppVersion(msg, url, important) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(msg),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('ตกลง'),
              onPressed: () {
                if (important == "1") {
                  _launchInBrowser(url);
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchInBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: false,
        forceWebView: false,
        headers: <String, String>{'my_header_key': 'my_header_value'},
      );
      exit(0);
    } else {
      throw 'Could not launch $url';
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iSmart Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashscreenScreen(),
      builder: (context, child) =>
          FlutterEasyLoading(child: child ?? Container()),
    );
  }
}

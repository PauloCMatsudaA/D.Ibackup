import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';
class ServicoNotificacao {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); 

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {

      },
    );
  }

  static Future<void> mostrarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
    String? payload,
  }) async {
     AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', 
      'Notificações de Detecção', 
      channelDescription: 'Canal para alertas de detecção de celular',
      importance: Importance.max, 
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alerta_celular'), 
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      sound: 'alerta_celular.aiff', 
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

     NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      titulo,
      corpo,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}
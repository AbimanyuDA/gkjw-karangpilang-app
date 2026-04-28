// lib/data/services/notification_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/supabase_models.dart';

enum NotificationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'sapaan_channel';
  static const String _channelName = 'Sapaan Harian';
  static const int _idPagi = 1;
  static const int _idMalam = 2;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // Create Android notification channel with high importance
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifikasi sapaan harian berisi ayat Alkitab',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  Future<NotificationPermissionStatus> checkAndRequestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final enabled = await androidPlugin?.areNotificationsEnabled() ?? true;
      debugPrint('Android notifications enabled: $enabled');

      if (enabled) return NotificationPermissionStatus.granted;

      final granted = await androidPlugin?.requestNotificationsPermission();
      debugPrint('Android requestNotificationsPermission: $granted');

      if (granted == null || granted == true) {
        return NotificationPermissionStatus.granted;
      }

      final phStatus = await ph.Permission.notification.status;
      if (phStatus.isPermanentlyDenied) {
        return NotificationPermissionStatus.permanentlyDenied;
      }
      return NotificationPermissionStatus.denied;
    }

    if (Platform.isIOS) {
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      final result = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('iOS requestPermissions result: $result');

      if (result == true || result == null) {
        return NotificationPermissionStatus.granted;
      }

      // Double-check with permission_handler
      final phStatus = await ph.Permission.notification.status;
      debugPrint('iOS ph status: $phStatus');

      if (phStatus.isGranted || phStatus.isProvisional) {
        return NotificationPermissionStatus.granted;
      }

      return NotificationPermissionStatus.permanentlyDenied;
    }

    return NotificationPermissionStatus.granted;
  }

  Future<void> openNotificationSettings() async {
    await ph.openAppSettings();
  }

  Future<bool> requestPermission() async {
    final status = await checkAndRequestPermission();
    return status == NotificationPermissionStatus.granted;
  }

  Future<void> showTestNotification({
    required String judul,
    required String pesan,
  }) async {
    if (!_initialized) await initialize();

    debugPrint('Showing test notification: $judul');

    await _plugin.show(
      99,
      judul,
      pesan,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Notifikasi sapaan harian berisi ayat Alkitab',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
          styleInformation: BigTextStyleInformation(pesan),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );

    debugPrint('Test notification sent successfully');
  }

  Future<void> scheduleSapaanPagi(SapaanConfigModel config) async {
    if (!_initialized) await initialize();
    await _plugin.cancel(_idPagi);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      config.jamPagi,
      config.menitPagi,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _idPagi,
      'Sapaan Pagi',
      config.ayatPagi,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Notifikasi sapaan harian berisi ayat Alkitab',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(config.ayatPagi),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('Sapaan Pagi scheduled at ${config.jamPagi}:${config.menitPagi.toString().padLeft(2, '0')}');
  }

  Future<void> scheduleSapaanMalam(SapaanConfigModel config) async {
    if (!_initialized) await initialize();
    await _plugin.cancel(_idMalam);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      config.jamMalam,
      config.menitMalam,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _idMalam,
      'Sapaan Malam',
      config.ayatMalam,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Notifikasi sapaan harian berisi ayat Alkitab',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(config.ayatMalam),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('Sapaan Malam scheduled at ${config.jamMalam}:${config.menitMalam.toString().padLeft(2, '0')}');
  }

  Future<void> cancelSapaanPagi() async {
    await _plugin.cancel(_idPagi);
    debugPrint('Sapaan Pagi cancelled');
  }

  Future<void> cancelSapaanMalam() async {
    await _plugin.cancel(_idMalam);
    debugPrint('Sapaan Malam cancelled');
  }
}

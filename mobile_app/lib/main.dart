import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // 1. Add this import

import 'app.dart';
import 'services/firebase/firebase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/plant_provider.dart';
import 'providers/diary_provider.dart';
import 'providers/iot_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/statistics_provider.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.initialize();
  
  // 2. Add App Check Activation here
  // This explicitly sets the provider to 'debug' for Android to fix your log warning
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.appAttest,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PlantProvider()),
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
        ChangeNotifierProvider(create: (_) => IotProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
      ],
      child: const PlantCareApp(),
    ),
  );
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:thesis_drivers_app_module/firebase_options.dart';
import 'package:thesis_drivers_app_module/pages/dashboard.dart';
import 'package:thesis_drivers_app_module/pages/home_page.dart';

import 'authentication/login_screen.dart';


Future<void> main()async {
  WidgetsFlutterBinding.ensureInitialized();

  // Generate permission request for location
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Permission.locationWhenInUse.isDenied.then((valueOfPermission)
  {
    if(valueOfPermission)
    {
      Permission.locationWhenInUse.request();
    }
  });

  // generate permission request for push notifications
  await Permission.notification.isDenied.then((valueOfPermission)
  {
    if(valueOfPermission)
    {
      Permission.notification.request();
    }
  });

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drivers App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black87,

      ),
      // if user is not logged in -> LoginScreen else -> Resume to Home Page
      home: FirebaseAuth.instance.currentUser == null ? LoginScreen() : Dashboard(),
    );
  }
}


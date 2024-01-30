import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationSystem
{
  FirebaseMessaging firebaseCloudMessaging = FirebaseMessaging.instance;

  // generate unique FCM token for each driver
  Future<String?> generateDeviceRegistrationToken() async
  {
    String? deviceRecognitionToken = await firebaseCloudMessaging.getToken();

    DatabaseReference referenceOnlineDriver = FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("deviceToken");

    referenceOnlineDriver.set(deviceRecognitionToken);

    firebaseCloudMessaging.subscribeToTopic("drivers");
    firebaseCloudMessaging.subscribeToTopic("users");

  }

  // listening for new notifications (covers 3 scenarios)
  startListeningForNewNotification()
  {
    // 1. App is terminated (app completely closed)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? messageRemote)
    {
     if(messageRemote != null)
       {
         String tripID =  messageRemote.data["tripID"];
       }
    });

    // 2. Fpreground (app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage? messageRemote)
    {
      if(messageRemote != null)
      {
        String tripID =  messageRemote.data["tripID"];
      }
    });

    // 3. Background (app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? messageRemote)
    {
      if(messageRemote != null)
      {
        String tripID =  messageRemote.data["tripID"];
      }
    });
    
  }

}

import 'dart:async';
import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:thesis_drivers_app_module/global/global_var.dart';
import 'package:thesis_drivers_app_module/models/trip_details.dart';
import 'package:thesis_drivers_app_module/widgets/loading_dialog.dart';
import 'package:thesis_drivers_app_module/widgets/notification_dialog.dart';
import 'dart:developer';

class PushNotificationSystem
{
  FirebaseMessaging firebaseCloudMessaging = FirebaseMessaging.instance;
  StreamSubscription<DatabaseEvent>? DispatchStreamSubscription;
  List<String> tripIDs = [];
  List<LatLng> pickUpLatLangs = [];
  List pickUpAddresses = [];

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

    return null;
  }

  // listening for new notifications (covers 3 scenarios)
  startListeningForNewNotification(BuildContext context){
    // 1. App is terminated (app completely closed)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? messageRemote)
    {
     if(messageRemote != null)
       {
         String tripID =  messageRemote.data["tripID"];
         sleep(const Duration(seconds: 5));
         retrieveTripRequestInfo(tripID, context);
       }
    });

    // 2. Foreground (app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage? messageRemote)
    {

      if(messageRemote != null)
      {
        String tripID =  messageRemote.data["tripID"];
        sleep(const Duration(seconds: 5));
        retrieveTripRequestInfo(tripID, context);

      }
    });

    // 3. Background (app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? messageRemote)
    {
      if(messageRemote != null)
      {
        String tripID =  messageRemote.data["tripID"];
        sleep(const Duration(seconds: 5));
        retrieveTripRequestInfo(tripID, context);

      }
    });
  }

  retrieveTripRequestInfo(tripID, BuildContext context) async {
    var dispatchStatus =  FirebaseDatabase.instance.ref().child("tripRequests").child(tripID);
     await dispatchStatus.once().then((snap) {
         if((snap.snapshot.value as Map)["dispatchStatus"] == "accept" ){
           tripIDs.add(tripID);
           showDialog(
             context: context,
             barrierDismissible: false,
             builder: (BuildContext context) =>
                 const LoadingDialog(messageText: "Getting Details"),
           );
          DatabaseReference tripRequestRef = FirebaseDatabase.instance.ref().child("tripRequests").child(tripID);
          tripRequestRef.once().then((dataSnapshot) {
            Navigator.pop(context);

            //play notification sound
            audioPlayer.open(
              Audio("assets/audio/alert_sound.mp3"),
            );
            audioPlayer.play();

            TripDetails tripDetailsInfo = TripDetails();
            double pickUpLat = double.parse((dataSnapshot.snapshot.value! as Map)["pickUpLatLng"]["latitude"]);
            double pickUpLng = double.parse((dataSnapshot.snapshot.value! as Map)["pickUpLatLng"]["longitude"]);
            tripDetailsInfo.pickUpLatLng = LatLng(pickUpLat, pickUpLng);
            pickUpLatLangs.add(LatLng(pickUpLat, pickUpLng));

            log("pickUpLatLangs: $pickUpLatLangs");

            tripDetailsInfo.pickUpAddress = (dataSnapshot.snapshot.value! as Map)["pickUpAddress"];
            pickUpAddresses.add({"address": tripDetailsInfo.pickUpAddress});
            log("pickUpAddresses : $pickUpAddresses");

            double dropOffLat = double.parse((dataSnapshot.snapshot.value! as Map)["dropOffLatLng"]["latitude"]);
            double dropOffLng = double.parse((dataSnapshot.snapshot.value! as Map)["dropOffLatLng"]["longitude"]);
            tripDetailsInfo.dropOffLatLng = LatLng(dropOffLat, dropOffLng);

            tripDetailsInfo.dropOffAddress = (dataSnapshot.snapshot.value! as Map)["dropOffAddress"];

            tripDetailsInfo.userName = (dataSnapshot.snapshot.value! as Map)["userName"];
            tripDetailsInfo.userPhone = (dataSnapshot.snapshot.value! as Map)["userPhone"];
            tripDetailsInfo.userEmail = (dataSnapshot.snapshot.value! as Map)["userEmail"];

            tripDetailsInfo.tripID = tripID;

            showDialog(
              context: context,
              builder: (BuildContext context) =>
                  NotificationDialog(tripDetailsInfo: tripDetailsInfo,),
            );

            Map <String, dynamic> tripIDDetails = {
              "pickUpAddress" : tripDetailsInfo.pickUpAddress,
              "latitude" : pickUpLat,
              "longitude" : pickUpLng,
              "email" : tripDetailsInfo.userEmail,
              "username" : tripDetailsInfo.userName,
              "userphone" :tripDetailsInfo.userPhone
            };

            DatabaseReference driverTripIDDetails = FirebaseDatabase.instance.ref().child("drivers")
                .child(FirebaseAuth.instance.currentUser!.uid).child("tripDetails").child(tripID);

            driverTripIDDetails.update(tripIDDetails);

          });
        }
    });
  }
}

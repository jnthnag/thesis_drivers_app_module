import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:thesis_drivers_app_module/authentication/login_screen.dart';
import 'package:thesis_drivers_app_module/pages/about_page.dart';
import '../global/global_var.dart';
import '../methods/map_theme_methods.dart';
import '../pushNotification/push_notification_system.dart';
import 'new_trip_page.dart';
import 'package:thesis_drivers_app_module/models/trip_details.dart';



class HomePageFinal extends StatefulWidget {

  TripDetails? tripDetailsInfo;
  HomePageFinal({super.key, this.tripDetailsInfo});

  @override
  State<HomePageFinal> createState() => _HomePageState();
}

class _HomePageState extends State<HomePageFinal> {
  /// variables used
  final Completer<GoogleMapController> googleMapCompleterController = Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  DatabaseReference? newTripRequestReference;
  Position? currentPositionOfDriver;
  Color colorToShow = Colors.green;
  String titleToShow = "GO OFFLINE NOW";
  bool isDriverAvailable = true;
  bool isDrawerOpened = true;
  double searchHeightContainer = 276;
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  MapThemeMethods themeMethods = MapThemeMethods();
  List<String> waypointsTest = [];
  List<String> tripIDs = [];
  List<LatLng> pickUpLatLng = [];
  List<String> email = [];
  List<String> username = [];
  List<String> userphone = [];
  List<String> pickUpAddress = [];


  var finalWaypointsTest;
  var finalWaypoints;


  getCurrentLiveLocationOfDriver()async
  {
    Position positionOfUser = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfDriver = positionOfUser;
    driverCurrentPosition = currentPositionOfDriver;

    LatLng LatLngUserPosition = LatLng(currentPositionOfDriver!.latitude, currentPositionOfDriver!.longitude);

    CameraPosition cameraPosition = CameraPosition(target: LatLngUserPosition, zoom: 75);

    controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  goOnlineNow()
  {
    // all drivers who are available for trip requests
    Geofire.initialize("onlineDrivers");

    // get active driver location, under each unique driver ID and store in database
    Geofire.setLocation(
        FirebaseAuth.instance.currentUser!.uid,
        currentPositionOfDriver!.latitude,
        currentPositionOfDriver!.longitude
    );

    // with location above, this method will update the location of the driver every n seconds
    // status: Waiting - On Trip -> Ended
    newTripRequestReference = FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("newTripStatus");
    newTripRequestReference!.set("waiting");

    newTripRequestReference!.onValue.listen((event) { });
  }

  goOfflineNow()
  {
    // stop sharing live location
    Geofire.removeLocation(FirebaseAuth.instance.currentUser!.uid);

    // stop listening to new trips status
    newTripRequestReference!.onDisconnect();
    newTripRequestReference!.remove();
    newTripRequestReference = null;
  }

  setAndGetLocationUpdates()
  {
    positionStreamHomePage = Geolocator.getPositionStream()
        .listen((Position position)
    {
      currentPositionOfDriver = position;

      if(isDriverAvailable == true) // updating drivers geo coordinates only if the driver is online
          {
        Geofire.setLocation(FirebaseAuth.instance.currentUser!.uid,
          currentPositionOfDriver!.latitude,
          currentPositionOfDriver!.longitude,
        );
      }

      LatLng positionLatLng = LatLng(position.latitude, position.longitude);
      controllerGoogleMap!.animateCamera(CameraUpdate.newLatLng(positionLatLng));
    });
  }

  initializePushNotificationSystem()
  {
    PushNotificationSystem notificationSystem =  PushNotificationSystem();
    notificationSystem.generateDeviceRegistrationToken();
    notificationSystem.startListeningForNewNotification(context);
  }

  retrieveCurrentDriverInfo() async
  {
    await FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .once().then((snap)
    {
      driverName = (snap.snapshot.value as Map)["name"];
      driverPhone = (snap.snapshot.value as Map)["phone"];
      driverPhoto = (snap.snapshot.value as Map)["photo"];
      carColor = (snap.snapshot.value as Map)["car_details"]["carColor"];
      carModel = (snap.snapshot.value as Map)["car_details"]["carModel"];
      carPlateNumber = (snap.snapshot.value as Map)["car_details"]["carPlateNumber"];
    });

    initializePushNotificationSystem();
  }

  obtainWaypoints()  {
    DatabaseReference tripDetailsRef =  FirebaseDatabase.instance.ref().child("drivers").child(FirebaseAuth.instance.currentUser!.uid).child("tripDetails");

    tripDetailsRef.onValue.listen((snap) {
      Map tripDetailsMap = snap.snapshot.value as Map;
      List tripDetailsList = [];
      tripDetailsMap.forEach((key, value) {
        tripDetailsList.add({"key": key, ...value});
      });
      for(var tripDetails in tripDetailsList)
      {
        waypointsTest.add(tripDetails["pickUpAddress"]);
      }
      if(waypointsTest.length > 1){
        finalWaypoints = jsonEncode(finalWaypointsTest = waypointsTest.join("|"));
      }else{
        finalWaypoints = jsonEncode(waypointsTest);
      }
    });
    return finalWaypoints;
  }

  obtainPickUpAddress(){
    DatabaseReference tripDetailsRef =  FirebaseDatabase.instance.ref().child("drivers").child(FirebaseAuth.instance.currentUser!.uid).child("tripDetails");

    tripDetailsRef.onValue.listen((snap) {
      Map tripDetailsMap = snap.snapshot.value as Map;
      List tripDetailsList = [];
      tripDetailsMap.forEach((key, value) {
        tripDetailsList.add({"key": key, ...value});
      });
      for(var tripDetails in tripDetailsList)
      {
        pickUpAddress.add(tripDetails["pickUpAddress"]);
      }
    });
    return pickUpAddress;
  }

  obtainTripIDs() {
    DatabaseReference tripDetailsRef = FirebaseDatabase.instance.ref().child("drivers").child(FirebaseAuth.instance.currentUser!.uid).child("tripDetails");

    tripDetailsRef.onValue.listen((snap) {
      Map tripDetailsMap = snap.snapshot.value as Map;
      List tripDetailsList = [];
      tripDetailsMap.forEach((key, value) {
        tripDetailsList.add({"key": key, ...value});
      });
      for(var tripDetails in tripDetailsList)
      {
        tripIDs.add(tripDetails["key"]);
      }
    });
    return tripIDs;
  }

  obtainPickUpLatLng(){
    DatabaseReference tripDetailsRef = FirebaseDatabase.instance.ref().child("drivers").child(FirebaseAuth.instance.currentUser!.uid).child("tripDetails");

    tripDetailsRef.onValue.listen((snap) {
      Map tripDetailsMap = snap.snapshot.value as Map;
      List tripDetailsList = [];
      tripDetailsMap.forEach((key, value) {
        tripDetailsList.add({"key": key, ...value});
      });
      for(var tripDetails in tripDetailsList)
      {
        pickUpLatLng.add(LatLng(tripDetails["latitude"], tripDetails["longitude"]));
      }
    });
    return pickUpLatLng;
  }

  obtainEmail(){
    DatabaseReference tripDetailsRef = FirebaseDatabase.instance.ref().child("drivers").child(FirebaseAuth.instance.currentUser!.uid).child("tripDetails");

    tripDetailsRef.onValue.listen((snap) {
      Map tripDetailsMap = snap.snapshot.value as Map;
      List tripDetailsList = [];
      tripDetailsMap.forEach((key, value) {
        tripDetailsList.add({"key": key, ...value});
      });
      for(var tripDetails in tripDetailsList)
      {
        email.add(tripDetails["email"]);
      }
    });
    return email;
  }

  obtainUsername(){
    DatabaseReference tripDetailsRef = FirebaseDatabase.instance.ref().child("drivers").child(FirebaseAuth.instance.currentUser!.uid).child("tripDetails");

    tripDetailsRef.onValue.listen((snap) {
      Map tripDetailsMap = snap.snapshot.value as Map;
      List tripDetailsList = [];
      tripDetailsMap.forEach((key, value) {
        tripDetailsList.add({"key": key, ...value});
      });
      for(var tripDetails in tripDetailsList)
        {
          username.add(tripDetails["username"]);
      }
    });
    return username;
  }

  obtainUserphone(){
    DatabaseReference tripDetailsRef = FirebaseDatabase.instance.ref().child("drivers").child(FirebaseAuth.instance.currentUser!.uid).child("tripDetails");

    tripDetailsRef.onValue.listen((snap) {
      Map tripDetailsMap = snap.snapshot.value as Map;
      List tripDetailsList = [];
      tripDetailsMap.forEach((key, value) {
        tripDetailsList.add({"key": key, ...value});
      });
      for(var tripDetails in tripDetailsList)
      {
        userphone.add(tripDetails["userphone"]);
        log("userphone : $userphone");
      }
    });
    return userphone;
  }




  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    retrieveCurrentDriverInfo();
  }

  resetAppNow()
  {
    setState(() {

      isDrawerOpened = true;

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key:sKey,
      drawer: Container(
        width: 230,
        color: Colors.amber,
        child: Drawer(
          backgroundColor: Colors.white10,
          child: ListView(
            children: [

              //header
              Container(
                color: Colors.amber,
                height: 160,
                child: DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/images/avatarman.png",
                        width: 60,
                        height: 60,
                      ),

                      const SizedBox(width : 16,),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo
                            ),
                          ),
                          const Text(
                            "Profile",
                            style: TextStyle(
                              color: Colors.indigo,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(
                height: 1,
                color: Colors.indigo,
                thickness: 1,
              ),

              const SizedBox(height: 10,),

              //body
              GestureDetector(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (c) => AboutPage()));
                },
                child: ListTile(
                  leading: IconButton(
                      onPressed: (){
                        Navigator.push(context, MaterialPageRoute(builder: (c) => AboutPage()));
                      },
                      icon: const Icon(Icons.info, color: Colors.indigo,)
                  ),
                  title: const Text("About", style: TextStyle(color: Colors.indigo),),
                ),
              ),

              GestureDetector(
                onTap: (){
                  FirebaseAuth.instance.signOut();
                  Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen()));
                },
                child: ListTile(
                  leading: IconButton(
                      onPressed: (){
                        FirebaseAuth.instance.signOut();
                        Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen()));
                      },
                      icon: const Icon(Icons.logout, color: Colors.indigo,)
                  ),
                  title: const Text("Logout", style: TextStyle(color: Colors.indigo),),

                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [

          // google map
          GoogleMap(
            padding: const EdgeInsets.only(top: 136),
            myLocationEnabled: true,
            mapType: MapType.normal,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController)
            {
              controllerGoogleMap = mapController;
              themeMethods.updateMapTheme(controllerGoogleMap!);

              googleMapCompleterController.complete(controllerGoogleMap);

              getCurrentLiveLocationOfDriver();
              obtainWaypoints();
              obtainPickUpLatLng();
              obtainTripIDs();
              obtainEmail();
              obtainUsername();
              obtainUserphone();
              obtainPickUpAddress();
            },
          ),

          Positioned(
            top: 165,
            left: 19,
            child: GestureDetector(
              onTap: ()
              {
                if(isDrawerOpened == true) {
                  sKey.currentState!.openDrawer();
                }
                else{
                  resetAppNow();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const
                    [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      )
                    ]
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.amber,
                  radius: 20,
                  child: Icon(
                    isDrawerOpened == true ? Icons.menu : Icons.close,
                    color: Colors.indigo,
                  ),
                ),
              ),

            ),
          ),

          Positioned(
              left: 0,
              right: 0,
              bottom: -80,
              // ignore: sized_box_for_whitespace
              child:  Container(
                height: searchHeightContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(onPressed: () async {
                      Navigator.push(context, MaterialPageRoute(builder: (c)=> NewTripPage(newTripDetailsInfo: widget.tripDetailsInfo, finalWaypoints: [finalWaypoints], tripIds: [tripIDs], pickUpLatLng: [pickUpLatLng], emailAddress: [email], userName: [username], userPhone: [userphone], pickUpAddress: [pickUpAddress],)));
                    },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24),
                      ),
                      child: const Icon(
                        Icons.route,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),

                    ElevatedButton(onPressed: (){

                    },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24),

                      ),
                      child: const Icon(
                        Icons.home,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),

                    ElevatedButton(onPressed: (){

                    },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24),

                      ),
                      child: const Icon(
                        Icons.work,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),

                  ],
                ),
              )),

          Container(
            height: 135,
            width: double.infinity,
            color: Colors.black54,
          ),

          // Set driver to online or offline button
          Positioned(
            top: 61,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                ElevatedButton(
                  onPressed: ()
                  {
                    showModalBottomSheet(
                        context: context,
                        isDismissible: false,
                        builder: (BuildContext context)
                        {
                          return Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey,
                                  blurRadius: 5.0,
                                  spreadRadius: 0.5,
                                  offset: Offset(
                                      0.7,
                                      0.7
                                  ),
                                ),
                              ],
                            ),
                            height: 220,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                              child: Column(
                                children: [

                                  const SizedBox(height: 11,),

                                  Text(
                                    (!isDriverAvailable) ? "GO ONLINE NOW" : "GO OFFLINE NOW",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  Text(
                                    (!isDriverAvailable)
                                        ? "Going online... Prepare to receive trip requests from Dispatcher"
                                        : "Going offline... You won't be able to receive trip requests",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: Colors.white30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 25,),

                                  Row(
                                    children: [

                                      Expanded(child: ElevatedButton(
                                        onPressed: ()
                                        {
                                          Navigator.pop(context);
                                        },
                                        child: const Text(
                                            "BACK"
                                        ),
                                      ),
                                      ),

                                      const SizedBox(width: 16,),

                                      Expanded(child: ElevatedButton(
                                        onPressed: ()
                                        {
                                          //
                                          if(!isDriverAvailable)
                                          {
                                            // go online
                                            goOnlineNow();

                                            // get driver location updates real time
                                            setAndGetLocationUpdates();

                                            Navigator.pop(context);

                                            setState(() {
                                              colorToShow = Colors.pink;
                                              titleToShow = "GO OFFLINE NOW";
                                              isDriverAvailable = true;
                                            });
                                          }

                                          else
                                          {
                                            // go offline
                                            goOfflineNow();

                                            // stop location sharing

                                            Navigator.pop(context);

                                            setState(() {
                                              colorToShow = Colors.green;
                                              titleToShow = "GO ONLINE NOW";
                                              isDriverAvailable = false;
                                            });
                                          }

                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                          (titleToShow == "GO ONLINE NOW")
                                              ? Colors.green : Colors.green,
                                        ),
                                        child: const Text(
                                            "CONFIRM"
                                        ),
                                      ),
                                      ),

                                    ],
                                  ),

                                ],
                              ),
                            ),
                          );
                        }
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorToShow,
                  ),
                  child: Text(
                      titleToShow
                  ),
                )

              ],
            ),
          ),

        ],
      ),
    );
  }
}

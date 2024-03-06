import 'dart:async';
import 'dart:convert';
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



class HomePage extends StatefulWidget {

  TripDetails? tripDetailsInfo;
  HomePage({super.key, this.tripDetailsInfo});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// variables used
  final Completer<GoogleMapController> googleMapCompleterController = Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  DatabaseReference? newTripRequestReference;
  Position? currentPositionOfDriver;
  Color colorToShow = Colors.green;
  String titleToShow = "GO ONLINE NOW";
  bool isDriverAvailable = false;
  bool isDrawerOpened = true;
  double searchHeightContainer = 276;
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  MapThemeMethods themeMethods = MapThemeMethods();


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
        width: MediaQuery.of(context).size.width * 0.55,
        decoration: const BoxDecoration(
            color: Color(0xFF61A3BA),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(18), // More rounded on the top-right corner
              bottomRight: Radius.circular(18), // More rounded on the bottom-right corner
          ),
        ),
        child: Drawer(
          backgroundColor: Color(0xFF61A3BA),
          child: ListView(
            children: [

              //header
              Container(
                height: 160,
                child: DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color(0xFF61A3BA)
                  ),
                  child: Column(
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
                              fontFamily: "Aeonik",
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
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
                      icon: const Icon(
                        Icons.info,
                        color:
                            Colors.white,
                      )
                  ),
                  title: const Text(
                    "About",
                    style:
                        TextStyle(
                          fontFamily: "Aeonik",
                            color: Colors.white
                        ),
                  ),
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
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white,
                      )
                  ),
                  title: const Text(
                    "Logout",
                    style: TextStyle(
                        fontFamily: "Aeonik",
                        color: Colors.white
                    ),
                  ),

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
                  backgroundColor: Colors.green.shade400,
                  radius: 20,
                  child: Icon(
                    isDrawerOpened == true ? Icons.menu : Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),

            ),
          ),

         /* Positioned(
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
                      Navigator.push(context, MaterialPageRoute(builder: (c)=> NewTripPage(newTripDetailsInfo: widget.tripDetailsInfo)));
                      isDriverAvailable = true;
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

                    *//*ElevatedButton(onPressed: (){

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
                    ),*//*

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
              )),*/

          Container(
            height: 135,
            width: MediaQuery.of(context).size.width,
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
                                        color: Colors.white,
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
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "Aeon"
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

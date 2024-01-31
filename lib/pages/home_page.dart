import 'dart:async';
import 'dart:convert';
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
import '../pushNotification/push_notification_system.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> googleMapCompleterController = Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  DatabaseReference? newTripRequestReference;
  Position? currentPositionOfUser;
  Color colorToShow = Colors.green;
  String titleToShow = "GO ONLINE NOW";
  bool isDriverAvailable = false;
  bool isDrawerOpened = true;
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();



  void updateMapTheme(GoogleMapController controller)
  {
    // defining the path of the Json file theme that we want to apply and assign it to "value"
    getJsonFileFromThemes("themes/night_theme.json").then ((value) => setGoogleMapStyle(value, controller));
  }

  Future<String> getJsonFileFromThemes(String mapStylePath) async
  {
    ByteData byteData = await rootBundle.load(mapStylePath);
    var list = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);

    return utf8.decode(list);
  }

  setGoogleMapStyle(String googleMapStyle,GoogleMapController controller)
  {
    // after passing the decoded value of the json file
    // to this function use setMapStyle to apply the theme
    controller.setMapStyle(googleMapStyle);
  }

  getCurrentLiveLocationOfDriver()async
  {
    Position positionOfUser = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfUser = positionOfUser;

    LatLng LatLngUserPosition = LatLng(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

    CameraPosition cameraPosition = CameraPosition(target: LatLngUserPosition, zoom: 15);

    controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    // await common.convertGeographicCoordinatesIntoHumanReadableAddress(currentPositionOfUser!, context);
    //
    // await getUserInfoAndCheckBlockStatus();
    //
    // await initializeGeoFireListener();
  }

  goOnlineNow()
  {
    // all drivers who are available for trip requests
    Geofire.initialize("onlineDrivers");

    // get active driver location, under each unique driver ID and store in database
    Geofire.setLocation(
        FirebaseAuth.instance.currentUser!.uid,
        currentPositionOfUser!.latitude,
        currentPositionOfUser!.longitude
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
      currentPositionOfUser = position;

      if(isDriverAvailable == true) // updating drivers geo coordinates only if the driver is online
        {
          Geofire.setLocation(FirebaseAuth.instance.currentUser!.uid,
              currentPositionOfUser!.latitude,
              currentPositionOfUser!.longitude,
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

  resetAppNow() {
    setState(() {

      isDrawerOpened = true;

    });
  }
  @override
  void initState() {
    super.initState();

    initializePushNotificationSystem();
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
              updateMapTheme(controllerGoogleMap!);

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

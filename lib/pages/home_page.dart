import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../global/global_var.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> googleMapCompleterController = Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser;
  Color colorToShow = Colors.green;
  String titleToShow = "GO ONLINE NOW";
  bool isDriverAvailable = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                                              // get driver location

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

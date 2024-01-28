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

          GoogleMap(
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
          )
        ],
      ),
    );;
  }
}

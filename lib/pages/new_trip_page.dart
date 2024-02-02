import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:thesis_drivers_app_module/models/trip_details.dart';
import 'package:thesis_drivers_app_module/widgets/loading_dialog.dart';
import '../global/global_var.dart';
import '../methods/map_theme_methods.dart';

class NewTripPage extends StatefulWidget
{
  TripDetails? newTripDetailsInfo;

  NewTripPage({super.key, this.newTripDetailsInfo,});

  @override
  State<NewTripPage> createState() => _NewTripPageState();
}

class _NewTripPageState extends State<NewTripPage> 
{
  final Completer<GoogleMapController> googleMapCompleterController = Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  MapThemeMethods themeMethods = MapThemeMethods();
  double googleMapPaddingFromBottom = 0;

  obtainDirectionAndDrawRoute(driverCurrentLocationLatLng, userPickUpLocationLatLng) async
  {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext) => LoadingDialog(messageText: "please wait...",)
    );


  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // google map
          GoogleMap(
            padding: EdgeInsets.only(top: googleMapPaddingFromBottom),
            myLocationEnabled: true,
            mapType: MapType.normal,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController) async
            {
              controllerGoogleMap = mapController;
              themeMethods.updateMapTheme(controllerGoogleMap!);
              googleMapCompleterController.complete(controllerGoogleMap);

              setState(() {
                googleMapPaddingFromBottom = 262;
              });

              var driverCurrentLocationLatLng = LatLng(
                  driverCurrentPosition!.latitude,
                  driverCurrentPosition!.longitude
              );

              var userPickUpLocationLatLng = widget.newTripDetailsInfo!.pickUpLatLng;

              await obtainDirectionAndDrawRoute(driverCurrentLocationLatLng, userPickUpLocationLatLng);


            },
          ),
        ],
      ),
    );
  }
}

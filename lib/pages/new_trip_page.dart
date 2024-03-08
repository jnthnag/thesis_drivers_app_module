import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sendgrid_mailer/sendgrid_mailer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../global/global_var.dart';
import '../methods/common_methods.dart';
import '../methods/map_theme_methods.dart';
import '../models/direction_details.dart';
import '../models/trip_details.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/payment_dialog.dart';
import 'dart:developer';


class NewTripPage extends StatefulWidget
{
  TripDetails? newTripDetailsInfo;
  List? tripIds;
  List? pickUpLatLng;
  List? pickUpAddress;
  List? finalWaypoints;
  List? emailAddress;
  List? userName;
  List? userPhone;

  NewTripPage({super.key, this.newTripDetailsInfo, this.finalWaypoints, this.pickUpLatLng, this.tripIds, this.emailAddress, this.userName, this.userPhone, this.pickUpAddress});

  @override
  State<NewTripPage> createState() => _NewTripPageState();
}

class _NewTripPageState extends State<NewTripPage>
{
  final Completer<GoogleMapController> googleMapCompleterController = Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  MapThemeMethods themeMethods = MapThemeMethods();
  double googleMapPaddingFromBottom = 0;
  List<LatLng> coordinatesPolylineLatLngList = [];
  PolylinePoints polylinePoints = PolylinePoints();
  Set<Marker> markersSet = Set<Marker>();
  Set<Circle> circlesSet = Set<Circle>();
  Set<Polyline> polyLinesSet = Set<Polyline>();
  BitmapDescriptor? carMarkerIcon;
  bool directionRequested = false;
  /*String statusOfTrip = "accepted";
  String durationText = "", distanceText = "";
  String buttonTitleText = "ARRIVED";
  Color buttonColor = Colors.indigoAccent;*/
  CommonMethods common = CommonMethods();
  LatLng dropOffLatLng = const LatLng(14.481952540896081,121.05271356403014);
  String dropOffAddress = "Mega Pacific Freight Logistics, Inc.";
  DirectionDetails? distanceDetails;
  var finalWaypoints;
  var finalWaypointsTest;




  makeMarker()
  {
    if(carMarkerIcon == null)
    {
      ImageConfiguration configuration = createLocalImageConfiguration(context, size: const Size(2, 2));

      BitmapDescriptor.fromAssetImage(configuration, "assets/images/tracking.png")
          .then((valueIcon)
      {
        carMarkerIcon = valueIcon;
      });
    }
  }

  obtainDirectionAndDrawRoute(LatLng sourceLocationLatLng, LatLng destinationLocationLatLng, waypoints) async
  {
    var finalWaypoints = widget.finalWaypoints!;
    List finalPickUpLatLng = widget.pickUpLatLng!.expand((e) => e).toList();
    //var finalWaypoints = ["SM City Bicutan - Basement Parking| SM Mall of Asia Pacific Dr| Vista GL Taft by Vista Residences | Adamson University Main Building |  Robinsons Place Manila| University Pad Residences Taft "];
    //var finalPickUpLatLng = widget.pickUpLatLng!;

    /*var finalPickUpLatLng = const [LatLng(14.563171438249386, 120.99660754139758),
    LatLng(14.575806318146906, 120.98390566355988),
    LatLng(14.585982799465254, 120.98539863895142),
    LatLng(14.579556636257582, 120.98681978313202),
    LatLng(14.535383780337185, 120.98310343990391),
    LatLng(14.486641629869697, 121.04244539389111)];*/

    //log("finalPickUpLatLng : $finalPickUpLatLng");


    //common.turnOffLocationUpdatesForHomePage();
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => LoadingDialog(messageText: 'Please wait...',)
    );



    var tripDetailsInfo = await CommonMethods.getDirectionDetailsFromAPI(
        sourceLocationLatLng,
        destinationLocationLatLng,
        finalWaypoints
    );

    Navigator.pop(context);

    PolylinePoints pointsPolyline = PolylinePoints();
    List<PointLatLng> latLngPoints = pointsPolyline.decodePolyline(tripDetailsInfo!.encodedPoints!);

    coordinatesPolylineLatLngList.clear();

    if(latLngPoints.isNotEmpty)
    {
      latLngPoints.forEach((PointLatLng pointLatLng)
      {
        coordinatesPolylineLatLngList.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    //draw polyline
    polyLinesSet.clear();

    setState(() {
      Polyline polyline = Polyline(
          polylineId: const PolylineId("routeID"),
          color: Colors.amber,
          points: coordinatesPolylineLatLngList,
          jointType: JointType.round,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true
      );

      polyLinesSet.add(polyline);
    });

    //fit the polyline on google map
    LatLngBounds boundsLatLng;

    if(sourceLocationLatLng.latitude > destinationLocationLatLng.latitude
        && sourceLocationLatLng.longitude > destinationLocationLatLng.longitude)
    {
      boundsLatLng = LatLngBounds(
        southwest: destinationLocationLatLng,
        northeast: sourceLocationLatLng,
      );
    }
    else if(sourceLocationLatLng.longitude > destinationLocationLatLng.longitude)
    {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(sourceLocationLatLng.latitude, destinationLocationLatLng.longitude),
        northeast: LatLng(destinationLocationLatLng.latitude, sourceLocationLatLng.longitude),
      );
    }
    else if(sourceLocationLatLng.latitude > destinationLocationLatLng.latitude)
    {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLocationLatLng.latitude, sourceLocationLatLng.longitude),
        northeast: LatLng(sourceLocationLatLng.latitude, destinationLocationLatLng.longitude),
      );
    }
    else
    {
      boundsLatLng = LatLngBounds(
        southwest: sourceLocationLatLng,
        northeast: destinationLocationLatLng,
      );
    }

    controllerGoogleMap!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 72));

    //add marker
    Marker sourceMarker = Marker(
      markerId: const MarkerId('sourceID'),
      position: sourceLocationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    for(int i = 0; i < finalPickUpLatLng.length; i++){
      LatLng currentCoordinate = finalPickUpLatLng[i];
      Marker marker = Marker(
        markerId: MarkerId('waypoint_$i'),
        position: currentCoordinate,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
      markersSet.add(marker);
    }

    Marker destinationMarker = Marker(
      markerId: const MarkerId('destinationID'),
      position: destinationLocationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );

    setState(() {
      markersSet.add(sourceMarker);
      markersSet.add(destinationMarker);
    });

    //add circle
    Circle sourceCircle = Circle(
      circleId: const CircleId('sourceCircleID'),
      strokeColor: Colors.orange,
      strokeWidth: 4,
      radius: 14,
      center: sourceLocationLatLng,
      fillColor: Colors.green,
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId('destinationCircleID'),
      strokeColor: Colors.green,
      strokeWidth: 4,
      radius: 14,
      center: destinationLocationLatLng,
      fillColor: Colors.orange,
    );

    setState(() {
      circlesSet.add(sourceCircle);
      circlesSet.add(destinationCircle);
    });
  }

  getLiveLocationUpdatesOfDriver()
  {
    positionStreamNewTripPage = Geolocator.getPositionStream().listen((Position positionDriver)
    {
      driverCurrentPosition = positionDriver;

      LatLng driverCurrentPositionLatLng = LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

      Marker carMarker = Marker(
        markerId: const MarkerId("carMarkerID"),
        position: driverCurrentPositionLatLng,
        icon: carMarkerIcon!,
        infoWindow: const InfoWindow(title: "My Location"),
      );

      setState(() {
        CameraPosition cameraPosition = CameraPosition(target: driverCurrentPositionLatLng, zoom: 16);
        controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

        markersSet.removeWhere((element) => element.markerId.value == "carMarkerID");
        markersSet.add(carMarker);
      });

      //update Trip Details Information
      /*updateTripDetailsInformation();*/

      //update driver location to tripRequest
      Map updatedLocationOfDriver =
      {
        "latitude": driverCurrentPosition!.latitude,
        "longitude": driverCurrentPosition!.longitude,
      };
      FirebaseDatabase.instance.ref().child("tripRequests")
          .child(widget.newTripDetailsInfo!.tripID!)
          .child("driverLocation")
          .set(updatedLocationOfDriver);
    });
  }

  /*updateTripDetailsInformation() async
  {
    if(!directionRequested)
    {
      directionRequested = true;

      if(driverCurrentPosition == null)
      {
        return;
      }

      var driverLocationLatLng = LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

      LatLng dropOffDestinationLocationLatLng;


      if(statusOfTrip == "accepted") // scenario 1: pick up order, driver drop off = USER pick up location
      {
        dropOffDestinationLocationLatLng = widget.newTripDetailsInfo!.pickUpLatLng!;
      }
      else // scenario 2: after order pickup: driver drop off = USER drop off location
      {
        dropOffDestinationLocationLatLng = dropOffLatLng;
      }

      var directionDetailsInfo = await CommonMethods.getDirectionDetailsFromAPI(driverLocationLatLng, dropOffLatLng, widget.finalWaypoints
      );

      if(directionDetailsInfo != null)
      {
        directionRequested = false;

        setState(() {
          distanceText = directionDetailsInfo.distanceTextString!;
          durationText = directionDetailsInfo.durationTextString!;

        });
      }
    }
  }*/

  endTripNow() async
  {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => LoadingDialog(messageText: 'Please wait...',),
    );

    var driverCurrentLocationLatLng = LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

    var directionDetailsEndTripInfo = await CommonMethods.getDirectionDetailsFromAPI(
      widget.newTripDetailsInfo!.pickUpLatLng!, //pickup
      driverCurrentLocationLatLng,
        widget.finalWaypoints
//destination
    );

    Navigator.pop(context);

    String fareAmount = (common.calculateFareAmount(directionDetailsEndTripInfo!)).toString();

    await FirebaseDatabase.instance.ref().child("tripRequests")
        .child(widget.newTripDetailsInfo!.tripID!)
        .child("fareAmount").set(fareAmount);

    await FirebaseDatabase.instance.ref().child("tripRequests")
        .child(widget.newTripDetailsInfo!.tripID!)
        .child("status").set("ended");
    
    await FirebaseDatabase.instance.ref().child("drivers").child(FirebaseAuth.instance.currentUser!.uid).
        child("tripDetails").remove();

    positionStreamNewTripPage!.cancel();

    //dialog for collecting fare amount
    displayPaymentDialog(fareAmount);

    //save fare amount to driver total earnings
    saveFareAmountToDriverTotalEarnings(fareAmount);
  }

  displayPaymentDialog(fareAmount)
  {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => PaymentDialog(fareAmount: fareAmount),
    );
  }

  saveFareAmountToDriverTotalEarnings(String fareAmount) async
  {
    DatabaseReference driverEarningsRef = FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("earnings");

    await driverEarningsRef.once().then((snap)
    {
      if(snap.snapshot.value != null)
      {
        double previousTotalEarnings = double.parse(snap.snapshot.value.toString());
        double fareAmountForTrip = double.parse(fareAmount);

        double newTotalEarnings = previousTotalEarnings + fareAmountForTrip;

        driverEarningsRef.set(newTotalEarnings);
      }
      else
      {
        driverEarningsRef.set(fareAmount);
      }
    });
  }

  saveDriverDataToTripInfo() async
  {
    Map<String, dynamic> driverDataMap =
    {
      "status": "accepted",
      "driverID": FirebaseAuth.instance.currentUser!.uid,
      "driverName": driverName,
      "driverPhone": driverPhone,
      "driverPhoto": driverPhoto,
      "carDetails": carColor + " - " + carModel + " - " + carPlateNumber,
    };

    Map<String, dynamic> driverCurrentLocation =
    {
      'latitude': driverCurrentPosition!.latitude.toString(),
      'longitude': driverCurrentPosition!.longitude.toString(),
    };

    await FirebaseDatabase.instance.ref()
        .child("tripRequests")
        .child(widget.newTripDetailsInfo!.tripID!)
        .update(driverDataMap);

    await FirebaseDatabase.instance.ref()
        .child("tripRequests")
        .child(widget.newTripDetailsInfo!.tripID!)
        .child("driverLocation").update(driverCurrentLocation);
  }

  void sendmail(emailAddress){
    final mailer = Mailer('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');
    final toAddress = Address(emailAddress);
    final fromAddress = Address('3pldispatchmanagementsystem@gmail.com');
    final content = Content('text/plain', 'Your E-receipt is here please view it. ');
    final subject = 'Your E-Receipt is Here';
    //final template_id = "d-b85aedb06e864b3bb1fb7934427875f7";
    final personalization = Personalization([toAddress]);

    final email =
    Email([personalization], fromAddress, subject, content: [content]);
    mailer.send(email).then((result) {
      print(result.isValue);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    saveDriverDataToTripInfo();
  }

/*  @override
  void dispose() {
    // Cancel the stream subscription when the widget is disposed
    positionStreamNewTripPage?.cancel();
    super.dispose();
  }*/

  /// START OF WIDGET BUILD
  @override
  Widget build(BuildContext context)
  {
    var finalTripIDs = widget.tripIds!.expand((e) => e).toList();
    var finalEmail = widget.emailAddress!.expand((e) => e).toList();
    var userPhone = widget.userPhone!.expand((e) => e).toList();
    var userName = widget.userName!.expand((e) => e).toList();
    var finalPickUpLatLng = widget.pickUpLatLng!.expand((e) => e).toList();
    var finalPickUpAddress = widget.pickUpAddress!.expand((e) => e).toList();

    log("email : $finalEmail");
    makeMarker();
    return Scaffold(
      body: Stack(
        children: [

          ///google map
          GoogleMap(
            padding: EdgeInsets.only(bottom: googleMapPaddingFromBottom),
            mapType: MapType.normal,
            myLocationEnabled: true,
            markers: markersSet,
            circles: circlesSet,
            polylines: polyLinesSet,
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

              await obtainDirectionAndDrawRoute(driverCurrentLocationLatLng, dropOffLatLng, widget.finalWaypoints
              );

              getLiveLocationUpdatesOfDriver();
            },
          ),

          ///trip details
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 300,
              child: ListView.builder(
                itemCount: finalTripIDs.length,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return tripDetails(
                    key: Key("counter-$index"),
                    userName: userName[index],
                    pickUpAddress: finalPickUpAddress[index],
                    pickUpLatLng: finalPickUpLatLng[index],
                    email: finalEmail[index],
                    dropOffAddress: dropOffAddress,
                    userPhone: userPhone[index],
                    tripID: finalTripIDs[index],);
                  }
                  ),
          ),

        ],
      ),
    );
  }
}

class tripDetails extends StatefulWidget {

  String? userName;
  String? userPhone;
  String? pickUpAddress;
  String? dropOffAddress;
  String? tripID;
  String? email;
  LatLng? pickUpLatLng;

  tripDetails({super.key, required this.userName, required this.userPhone, required this.pickUpAddress, required this.dropOffAddress, required this.tripID, required this.pickUpLatLng, required this.email});

  @override
  State<tripDetails> createState() => _tripDetailsState();
}

class _tripDetailsState extends State<tripDetails> {

  String statusOfTrip = "accepted";
  String buttonTitleText = "ARRIVED";
  Color buttonColor = Colors.indigoAccent;
  bool directionRequested = false;
  LatLng dropOffLatLng = const LatLng(14.481952540896081,121.05271356403014);
  String durationText = "", distanceText = "";
  CommonMethods common = CommonMethods();

  void sendmail(emailAddress){
    final mailer = Mailer('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');
    final toAddress = Address(emailAddress);
    final fromAddress = Address('3pldispatchmanagementsystem@gmail.com');
    final content = Content('text/plain', 'Your E-receipt is here please view it. ');
    final subject = 'Your E-Receipt is Here';
    //final template_id = "d-b85aedb06e864b3bb1fb7934427875f7";
    final personalization = Personalization([toAddress]);

    final email =
    Email([personalization], fromAddress, subject, content: [content]);
    mailer.send(email).then((result) {
      print(result.isValue);
    });
  }

  getLocationOfDriver(){
    positionStreamNewTripPage = Geolocator.getPositionStream().listen((Position positionDriver){
      driverCurrentPosition = positionDriver;

      updateTripDetailsInformation();
    });
  }

  updateTripDetailsInformation() async
  {
    if(!directionRequested)
    {
      directionRequested = true;

      if(driverCurrentPosition == null)
      {
        return;
      }

      var driverLocationLatLng = LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

      LatLng dropOffDestinationLocationLatLng;


      if(statusOfTrip == "accepted") // scenario 1: pick up order, driver drop off = USER pick up location
          {
        dropOffDestinationLocationLatLng = widget.pickUpLatLng!;
      }
      else // scenario 2: after order pickup: driver drop off = USER drop off location
          {
        dropOffDestinationLocationLatLng = dropOffLatLng;
      }

      var directionDetailsInfo = await CommonMethods.getDirectionDetailsFromAPIDurationDistance(driverLocationLatLng, dropOffDestinationLocationLatLng
      );

      if(directionDetailsInfo != null)
      {
        directionRequested = false;

        setState(() {
          distanceText = directionDetailsInfo.distanceTextString!;
          durationText = directionDetailsInfo.durationTextString!;

        });
      }
    }
  }

  endTripNow() async
  {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => LoadingDialog(messageText: 'Please wait...',),
    );

    var driverCurrentLocationLatLng = LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

    var directionDetailsEndTripInfo = await CommonMethods.getDirectionDetailsFromAPIDurationDistance(
        widget.pickUpLatLng!, //pickup
        driverCurrentLocationLatLng
//destination
    );

    Navigator.pop(context);

    String fareAmount = (common.calculateFareAmount(directionDetailsEndTripInfo!)).toString();

    await FirebaseDatabase.instance.ref().child("tripRequests")
        .child(widget.tripID!)
        .child("fareAmount").set(fareAmount);

    await FirebaseDatabase.instance.ref().child("tripRequests")
        .child(widget.tripID!)
        .child("status").set("ended");

    await FirebaseDatabase.instance.ref().child("drivers").child(FirebaseAuth.instance.currentUser!.uid).
    child("tripDetails").remove();

    positionStreamNewTripPage!.cancel();

    /* //dialog for collecting fare amount
    displayPaymentDialog(fareAmount);

    //save fare amount to driver total earnings
    saveFareAmountToDriverTotalEarnings(fareAmount);*/
  }


  @override
  Widget build(BuildContext context) {
    return  Padding(
        padding: EdgeInsets.all(8.0),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.only(topRight: Radius.circular(17), topLeft: Radius.circular(17)),
            boxShadow:
            [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 17,
                spreadRadius: 0.5,
                offset: Offset(0.7, 0.7),
              ),
            ],
          ),
          height: 256,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                //trip duration
                Center(
                  child: Text(
                    durationText + " - " + distanceText,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 5,),

                //user name - call user icon btn
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    //user name
                    Text(
                      widget.userName!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    //call user icon btn
                    GestureDetector(
                      onTap: ()
                      {
                        launchUrl(
                          Uri.parse(
                              "tel://${widget.userPhone!}"
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(
                          Icons.phone_android_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                  ],
                ),

                const SizedBox(height: 15,),

                // pickup icon and location
                Row(
                  children: [

                    Image.asset(
                      "assets/images/initial.png",
                      height: 16,
                      width: 16,
                    ),

                    Expanded(
                      child: Text(
                        widget.pickUpAddress!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                  ],
                ),

                const SizedBox(height: 15,),

                // drop-off icon and location
                Row(
                  children: [

                    Image.asset(
                      "assets/images/final.png",
                      height: 16,
                      width: 16,
                    ),

                    Expanded(
                      child: Text(
                        widget.dropOffAddress!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25,),

                Center(
                  child: ElevatedButton(
                    onPressed: () async
                    {

                      //handleButtonPress(statusOfTrip);
                      // execute statement when clicking ARRIVED BUTTON
                      if(statusOfTrip == "accepted")
                      {
                        if(mounted){
                          setState(() {
                            buttonTitleText = "START TRIP";
                            buttonColor = Colors.green;
                          });
                        }
                        statusOfTrip = "arrived";

                        // Navigator.pop(context);
                      }
                      // execute statement when clicking START TRIP BUTTON
                      else if(statusOfTrip == "arrived")
                      {
                        if(mounted){
                          setState(() {
                            buttonTitleText = "END TRIP";
                            buttonColor = Colors.amber;
                          });
                        }
                        statusOfTrip = "ontrip";

                        FirebaseDatabase.instance.ref()
                            .child("tripRequests")
                            .child(widget.tripID!)
                            .child("status").set("ontrip");
                      }
                      // execute statement when clicking END TRIP BUTTON
                      else if(statusOfTrip == "ontrip")
                      {
                        //end the trip
                        FirebaseDatabase.instance.ref()
                            .child("tripRequests")
                            .child(widget.tripID!)
                            .child("status").set("ended");
                        //send e-receipt to users
                        sendmail(widget.email);
                        endTripNow();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                    ),
                    child: Text(
                      buttonTitleText,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }
}

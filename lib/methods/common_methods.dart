import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:thesis_drivers_app_module/global/global_var.dart';
import 'package:http/http.dart' as http;

import '../models/direction_details.dart';
import 'dart:developer';


class CommonMethods
{
  TextEditingController userNameTextEditingController = TextEditingController();
  TextEditingController userPhoneTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  TextEditingController vehicleModelTextEditingController = TextEditingController();
  TextEditingController vehicleColorTextEditingController = TextEditingController();
  TextEditingController vehiclePlateNumberTextEditingController = TextEditingController();
  TextEditingController carTextEditingController = TextEditingController();

  // Check internet connection
  checkConnectivity(BuildContext context) async
  {
    var connectionResult = await Connectivity().checkConnectivity();

    if (connectionResult != ConnectivityResult.mobile && connectionResult != ConnectivityResult.wifi)
    {
      if (!context.mounted) return;
      displaySnackbar("You are not connected to the Internet.", context);
    }
  }

  // Bottom phone area snack bar
  displaySnackbar(String messageText, BuildContext context)
  {
    var snackBar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  turnOffLocationUpdatesForHomePage()
  {
    positionStreamHomePage!.pause();
    Geofire.removeLocation(FirebaseAuth.instance.currentUser!.uid);
  }

  turnOnLocationUpdatesForHomePage()
  {
    positionStreamHomePage!.resume();
    Geofire.setLocation(
      FirebaseAuth.instance.currentUser!.uid,
      driverCurrentPosition!.latitude,
      driverCurrentPosition!.longitude
    );
  }

  static sendRequestToAPI(String apiUrl) async
  {
    http.Response responseFromAPI = await http.get(Uri.parse(apiUrl));

    try
    {
      if(responseFromAPI.statusCode == 200)
      {
        String dataFromApi = responseFromAPI.body;
        var dataDecoded = jsonDecode(dataFromApi);
        return dataDecoded;
      }
      else
      {
        return "error";
      }
    }
    catch(errorMsg)
    {
      return "error";
    }
  }

  static sendRequestToRoutesAPI(LatLng source,LatLng destination, waypoints, String apiUrl) async {
    try {
      final response = await http.post(
        body: jsonEncode({
          "origin":{
            "location":{
              "latLng":{
                "latitude": source.latitude,
                "longitude": source.longitude
              }
            }
          },
          "destination":{
            "location":{
              "latLng":{
                "latitude": destination.latitude,
                "longitude": destination.longitude
              }
            }
          },
          "intermediates": [
            waypoints
          ],
          "travelMode": "DRIVE",
          "polylineQuality": "HIGH_QUALITY",
          "routingPreference":"TRAFFIC_AWARE_OPTIMAL",
          "routeModifiers": {
            "avoidTolls": true,
          },
          "computeAlternativeRoutes": false,
          "languageCode": "en-PH",
          "units": "METRIC"
        }),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': 'AIzaSyDjkmC-NlWZRmKqYttx8x-e_G29ZNFSLL4',
          'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.travelAdvisory.speedReadingIntervals,routes.legs.polyline.encodedPolyline,routes.legs.travelAdvisory.speedReadingIntervals',
        },
        Uri.parse(apiUrl),
      );
      if (response.statusCode == 200) {
        var dataDecoded = jsonDecode(response.body);
        return dataDecoded;
      }
    }
    catch (errorMsg) {
      return "error";
    }
  }


  static Future<DirectionDetails?> getDirectionDetailsFromAPI(LatLng source,LatLng destination, waypoints) async {
    String urlDirectionAPI = "https://maps.googleapis.com/maps/api/directions/json?&departure_time=now&destination=${destination.latitude},${destination.longitude}&origin=${source.latitude},${source.longitude}&mode=driving&waypoints=optimize:true|$waypoints&avoid=tolls&key=$googleMapKey";
    var responseFromDirectionAPI = await sendRequestToAPI(urlDirectionAPI);

    if (responseFromDirectionAPI == "error") {
      return null;
    }

    print(responseFromDirectionAPI);

    DirectionDetails detailsModel = DirectionDetails();
    detailsModel.distanceTextString =
    responseFromDirectionAPI["routes"][0]["legs"][0]["distance"]["text"];
    detailsModel.distanceValueDigits =
    responseFromDirectionAPI["routes"][0]["legs"][0]["distance"]["value"];

    detailsModel.durationTextString =
    responseFromDirectionAPI["routes"][0]["legs"][0]["duration"]["text"];
    detailsModel.durationValueDigits =
    responseFromDirectionAPI["routes"][0]["legs"][0]["duration"]["value"];

    detailsModel.encodedPoints =
    responseFromDirectionAPI["routes"][0]["overview_polyline"]["points"];


    return detailsModel;
  }

  ///routes API
  static Future<DirectionDetails?> postData(LatLng source,LatLng destination, waypoints) async {
    String apiUrl = "https://routes.googleapis.com/directions/v2:computeRoutes";

    var responseData = await sendRequestToRoutesAPI(source,destination,waypoints, apiUrl);

    log("response from API : $responseData");
    if (responseData == "error") {
      return null;
    }



    DirectionDetails detailsModel = DirectionDetails();
    detailsModel.distanceValueDigits = responseData["routes"][0]["distanceMeters"];
    detailsModel.durationTextString = responseData["routes"][0]["duration"];
    detailsModel.encodedPoints = responseData["routes"][0]["polyline"]["encodedPolyline"];


    return detailsModel;
  }

  /*///Directions API
  static Future<DirectionDetails?> getDirectionDetailsFromAPI(LatLng source, LatLng destination, waypoints) async
  {
    String urlDirectionsAPI = "https://maps.googleapis.com/maps/api/directions/json?destination=${destination.latitude},${destination.longitude}&origin=${source.latitude},${source.longitude}&mode=driving&waypoints=TriNoma&avoid=tolls&key=$googleMapKey";

    var responseFromDirectionsAPI = await sendRequestToAPI(urlDirectionsAPI);

    log("responseFromDirectionsAPI : $responseFromDirectionsAPI");

    if(responseFromDirectionsAPI == "error")
    {
      return null;
    }

    DirectionDetails detailsModel = DirectionDetails();

    detailsModel.distanceTextString = responseFromDirectionsAPI["routes"][0]["legs"][0]["distance"]["text"];
    detailsModel.distanceValueDigits = responseFromDirectionsAPI["routes"][0]["legs"][0]["distance"]["value"];

    detailsModel.durationTextString = responseFromDirectionsAPI["routes"][0]["legs"][0]["duration"]["text"];
    detailsModel.durationValueDigits = responseFromDirectionsAPI["routes"][0]["legs"][0]["duration"]["value"];

    detailsModel.encodedPoints = responseFromDirectionsAPI["routes"][0]["overview_polyline"]["points"];

    return detailsModel;
  }*/



  calculateFareAmount(DirectionDetails directionDetails)
  {
    double distancePerKmAmount = 0.4;
    double durationPerMinuteAmount = 0.3;
    double baseFareAmount = 2;

    double totalDistanceTravelFareAmount = (directionDetails.distanceValueDigits! / 1000) * distancePerKmAmount;
    double totalDurationSpendFareAmount = (directionDetails.durationValueDigits! / 60) * durationPerMinuteAmount;

    double overAllTotalFareAmount = baseFareAmount + totalDistanceTravelFareAmount + totalDurationSpendFareAmount;

    return overAllTotalFareAmount.toStringAsFixed(1);
  }
}



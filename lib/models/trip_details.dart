import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripDetails
{
  String? tripID;
  LatLng? pickUpLatLng; //convert to list
  String? pickUpAddress; //convert to list
  LatLng? dropOffLatLng; //can't say pa kasi mejo may algo dito na drop off ng isa is yung pick up ng next nearest delivery
  String? dropOffAddress; //stay as is
  String? userName; //convert to list
  String? userPhone; // convert to list
  String? userEmail;


  TripDetails(
      {
        this.tripID,
        this.pickUpLatLng,
        this.pickUpAddress,
        this.dropOffLatLng,
        this.dropOffAddress,
        this.userName,
        this.userPhone
      }
      );
}
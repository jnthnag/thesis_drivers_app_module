import 'dart:async';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String userName = "";
String googleMapKey = "AIzaSyDjkmC-NlWZRmKqYttx8x-e_G29ZNFSLL4";

const CameraPosition googlePlexInitialPosition = CameraPosition(
  target: LatLng(14.5586, 120.9896),
  zoom: 14.4746,
);

StreamSubscription<Position>? positionStreamHomePage;
Position? driverCurrentPosition;

int driverTripRequestTimeout = 20;

final audioPlayer = AssetsAudioPlayer();
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class MapThemeMethods
{
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
}
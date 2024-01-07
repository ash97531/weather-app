


import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService{

  static Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }


  static Future<String> getCityFromLatLng(lat,lon) async {
    try {
      print([lat,lon]);
      List<Placemark> placemarks = await placemarkFromCoordinates(
          lat, lon);
      Placemark place = placemarks[0];
      if(place.locality==null){
        return " ";
      }else{
        return place.locality!;
      }
    }catch(e){
      return Future.error("Something went wrong");
    }
  }

}
import 'dart:convert';
import 'dart:ui';
import 'package:assign/location_service.dart';
import 'package:assign/new_location.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:assign/envdata.dart';
import 'package:assign/weather_forecast_item.dart';
import 'package:uuid/uuid.dart';
import 'additionalinfoitem.dart';

class WeatherScreen extends StatefulWidget {
  WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  
  double temp = 0;
  String cityName = 'New Delhi';

  double lat = 28.7041;
  double lon = 77.1025;
  bool firstTime = true;


  @override
  void initState() {
    super.initState();
    getWeatherData();
  }



  Future<Map<String, dynamic>> getWeatherData() async {

    try {

      if(firstTime){
        try{
          Position position = await LocationService.determinePosition();
          lat=position.latitude;
          lon=position.longitude;
        }catch(e){}
      }
      firstTime=false;
      cityName = await LocationService.getCityFromLatLng(lat,lon);

      final res = await http.get( 
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&APPID=$weatherapikey',
        ),
      );

      final data = jsonDecode(res.body);

      if (data['cod'] != '200') {
        throw 'An unexpected error occurred / API limit exceeded';
      }

      dynamic tempData = data['list'][0]['main']['temp'];
      if (tempData is int) {
        temp = tempData.toDouble();
      } else if (tempData is double) {
        temp = tempData;
      } else {
        throw 'Unexpected temperature data type';
      }
      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Weather App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                getWeatherData();
              });
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),

      body: FutureBuilder(
        future: getWeatherData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          final data = snapshot.data!;
          final currentWeatherData = data['list'][0];
          final currentTemp = currentWeatherData['main']['temp'];
          final currentSky = currentWeatherData['weather'][0]['main'];
          final pressure = currentWeatherData['main']['pressure'];
          final windspeed = currentWeatherData['wind']['speed'];
          final humidity = currentWeatherData['main']['humidity'];
          final tempincelcius = currentTemp - 273.15;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomScrollView(
              shrinkWrap: true,
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    width: double.infinity,
                    child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 20,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10,
                              sigmaY: 10,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16, bottom: 16),
                              child: Column(
                                children: [
                                  Text(
                                    '${tempincelcius.toStringAsFixed(2)}° C',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  Icon(
                                    currentSky == 'Clouds'
                                        ? Icons.cloud
                                        : currentSky == 'Clear'
                                            ? Icons.wb_sunny
                                            : currentSky == 'Rain'
                                                ? Icons.beach_access
                                                : Icons.wb_twilight,
                                    size: 64,
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  Text(
                                    '$currentSky , $cityName',
                                    style: const TextStyle(
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 20,
                  ),
                ),
                // forecast card
                const SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Weather Forecast',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 12,
                  ),
                ),

                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (int i = 0; i < 7; i++)
                          HourlyForecast(
                            time: data['list'][i]['dt_txt']
                                .toString()
                                .substring(11, 16),
                            icon: data['list'][i]['weather'][0]['main'] ==
                                    'Clouds'
                                ? Icons.cloud
                                : data['list'][i]['weather'][0]['main'] == 'Clear'
                                    ? Icons.wb_sunny
                                    : data['list'][i]['weather'][0]['main'] ==
                                            'Rain'
                                        ? Icons.beach_access
                                        : Icons.wb_twilight,
                            temp: (data['list'][i]['main']['temp'] - 273.15)
                                .toStringAsFixed(2),
                          ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 16,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Additional Information',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 16,
                  ),
                ),

                SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      AdditionalnfoItem(
                        icon: Icons.water_drop,
                        label: 'Humidity',
                        value: humidity.toString(),
                      ),
                      AdditionalnfoItem(
                        icon: Icons.air_rounded,
                        label: 'Windspeed',
                        value: windspeed.toString(),
                      ),
                      AdditionalnfoItem(
                        icon: Icons.beach_access,
                        label: 'Pressure',
                        value: pressure.toString(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Container(
          height: 50,
          margin: const EdgeInsets.all(10),
          child: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewLocation()),
              );
              if(result != null){
                setState(() {
                  lat=result[0];
                  lon=result[1];
                });
              }
            },
            child: const Center(
              child: Text('Search for new city'),
            ),
          ),
        ),
    );
  }
}


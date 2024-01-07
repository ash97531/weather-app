import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';

import 'envdata.dart';

class NewLocation extends StatefulWidget {
  const NewLocation({super.key});

  @override
  State<NewLocation> createState() => _NewLocationState();
}

class _NewLocationState extends State<NewLocation> {

  var uuid = new Uuid();
  String _sessionToken = '1234567890';
  List<dynamic> _placeList = [];
  final _controller = TextEditingController();


  void getSuggestion(String input) async {
    String type = '(regions)';

    try{
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      String request = '$baseURL?input=$input&key=$kPLACES_API_KEY&sessiontoken=$_sessionToken';
      var response = await http.get(Uri.parse(request));
      // var data = json.decode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _placeList = json.decode(response.body)['predictions'];
        });
      } else {
        throw Exception('Failed to load predictions');
      }
    }catch(e){
      // toastMessage('success');
    }

  }

  _onChanged() {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }
    getSuggestion(_controller.text);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SizedBox(height: 40,),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: const Color.fromRGBO(0, 0, 0, 0.10),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 10.0),
                    Icon(Icons.search),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5.0),
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter new location',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontFamily: 'Urbanist',
                            ),
                          ),
                          onChanged: _onChanged(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _placeList.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () async {
                    List<Location> locations = await locationFromAddress(_placeList[index]['description']);
                    // widget.address = _placeList[index]['description'];
                    // print(locations.last.longitude);
                    double lat = locations.last.latitude;
                    double lon = locations.last.longitude;
                    Navigator.of(context).pop([lat,lon]);
                    _placeList.clear();
                    _controller.clear();
                  },
                  child: ListTile(
                    title: Text(_placeList[index]["description"]),
                  ),
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}

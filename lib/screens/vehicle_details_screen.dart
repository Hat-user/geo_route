import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geo_route/model/vehicle_details_model.dart';
import 'package:geo_route/server/api/update_api.dart';
import 'package:geo_route/server/api/vehicle_api.dart';
import 'package:geo_route/server/services/mapmyindia_config.dart';
import 'package:geo_route/utils/gap.dart';
import 'package:mapmyindia_gl/mapmyindia_gl.dart';
import 'package:url_launcher/url_launcher.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String id;
  const VehicleDetailsScreen({super.key, required this.id});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  late MapmyIndiaMapController _mapController;

  final VehicleApi vehicleApi = VehicleApi();
  late Future<VehicleDetailsModel> vehicleDetailsFuture;
  final TextEditingController _textFieldController = TextEditingController();
  final Map<String, dynamic> data = {
    "demo1": {
      "location": "Udaipur"
    },
    "demo2": {
      "location": "Jaipur"
    },
    "demo3": {
      "location": "Delhi"
    },
    "demo4": {
      "location": "Mumbai"
    },
    "demo5": {
      "location": "Kolkata"
    },
    "demo6": {
      "location": "Chennai"
    },
    "demo7": {
      "location": "Bangalore"
    },
    "demo8": {
      "location": "Hyderabad"
    },
    "demo9": {
      "location": "Ahmedabad"
    },
    "demo10": {
      "location": "Pune"
    },
    "demo11": {
      "location": "Surat"
    },
    "demo12": {
      "location": "Lucknow"
    },
    "demo13": {
      "location": "Chandigarh"
    },
    "demo14": {
      "location": "Bhopal"
    },
  };
  final List limitColor = [const AlwaysStoppedAnimation<Color>(Colors.green),const AlwaysStoppedAnimation<Color>(Colors.yellow),const AlwaysStoppedAnimation<Color>(Colors.red),];
  int colorIndex = 0;

  @override
  void initState() {
    MapmyIndiaAccountManager.setMapSDKKey(mapMyIndiaMapSdkKey);
    MapmyIndiaAccountManager.setRestAPIKey(mapMyIndiaRestApiKey);
    MapmyIndiaAccountManager.setAtlasClientId(mapMyIndiaAtlasClientId);
    MapmyIndiaAccountManager.setAtlasClientSecret(mapMyIndiaAtlasClientSecret);
    vehicleDetailsFuture = vehicleApi.getVehicleDetailsById(id: widget.id, role: 'ADMIN');
    super.initState();
  }

  void _onMapCreated(MapmyIndiaMapController controller) async {
    _mapController = controller;
    final vehicleDetails = await vehicleDetailsFuture;
    _mapController.clearSymbols();
    _addMarker(lat: vehicleDetails.lat, lng: vehicleDetails.lng);
  }

  void _addMarker({required double lat, required double lng}) {
    _mapController.addSymbol(SymbolOptions(
      geometry: LatLng(lat, lng),
      iconImage: "assets/marker.png",
      iconSize: 0.25,
    ));
  }

  Future<void> _openMap({required double latitude, required double longitude}) async {
    Uri url;
    if (Platform.isIOS) {
      url = Uri.parse('https://maps.apple.com/?daddr=$latitude,$longitude&dirflg=d');
    } else {
      url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving');
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      vehicleDetailsFuture = vehicleApi.getVehicleDetailsById(id: widget.id,role: 'ADMIN');
    });
    final vehicleDetails = await vehicleDetailsFuture;
    _mapController.clearSymbols();
    _addMarker(lat: vehicleDetails.lat, lng: vehicleDetails.lng);
  }

  String? userInput;

  Future<void> displayUpdateDialog({required String title,required String id}) async{
    showDialog(context: context, builder: (BuildContext context) {
      return Theme.of(context).platform == TargetPlatform.iOS ?
      CupertinoAlertDialog(

        title: Text(title),

        content: Column(
          children: [
            const Gap(10),
            CupertinoTextField(
              onChanged: (value) {
                setState(() {
                  userInput = value;
                });
              },
              keyboardType: TextInputType.number,
              controller: _textFieldController,
              placeholder: "Set new limit",
              style: const TextStyle(fontSize: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black, // Underline color
                    width: 1.0,        // Underline width
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: (){
            _textFieldController.clear();
            userInput = null;
            Navigator.of(context).pop();
          },),
          CupertinoDialogAction(child: const Text('Update'), onPressed: ()async{
            if(userInput != null && userInput!.isNotEmpty){
              await updateVehicleKmLimit(context: context, id: id, newLimit: int.parse(userInput!),refresh: _refreshData);
              _textFieldController.clear();
              userInput = null;
            }
          },)

        ],
      )
          : AlertDialog(

        title: Text(title),
        content: TextField(
          onChanged: (value) {
            setState(() {
              userInput = value;
            });
          },
          controller: _textFieldController,
          keyboardType: TextInputType.number,

          decoration: const InputDecoration(hintText: "Set new limit"),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              _textFieldController.clear();
              userInput = null;
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Update'),
            onPressed: () async {
              if (userInput != null && userInput!.isNotEmpty) {
                await updateVehicleKmLimit(context: context,
                    id: id,
                    newLimit: int.parse(userInput!),
                    refresh: _refreshData);
                _textFieldController.clear();
                userInput = null;
              }
            },
          ),
        ],
      );
    }
    );
  }

  @override
  Widget build(BuildContext context) {
    colorIndex = ((5080/ 6000) * 2).round();
    return Scaffold(
      appBar: AppBar(
        title: const Text("MAP"),
        centerTitle: true,
        elevation: 5,
        shadowColor: Colors.grey,
        actions: [
          IconButton(onPressed: _refreshData, icon: const Icon(Icons.refresh, size: 28,))
        ],
      ),
      body: FutureBuilder<VehicleDetailsModel>(
        future: vehicleDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Theme.of(context).platform == TargetPlatform.iOS
                  ? const CupertinoActivityIndicator(radius: 20)
                  : const CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No data found"));
          } else {
            final vehicleDetails = snapshot.data!;
            final totalRun = double.parse(vehicleDetails.vehicleNewKm);
            final limit = vehicleDetails.vehicleKMLimit;
            return Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: MapmyIndiaMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(vehicleDetails.lat, vehicleDetails.lng),
                      zoom: 15.0,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: GestureDetector(
                    onTap: () => _openMap(latitude: vehicleDetails.lat, longitude: vehicleDetails.lng),
                    child: const CircleAvatar(
                      backgroundColor: Colors.black87,
                      radius: 18,
                      child: Icon(Icons.directions, color: Colors.white),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.4,
                    minChildSize: 0.4,
                    builder: (context, scrollController) {
                      return Container(
                        height: MediaQuery.of(context).size.height,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicleDetails.vehicleNumber ?? "Unknown Vehicle",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                          Row(
                                            children: [
                                              const Icon(CupertinoIcons.person, size: 18,),
                                              Text(vehicleDetails.driverName ?? "Unknown driver"),
                                            ],
                                          ),
                                      Row(
                                        children: [
                                      const Icon(Icons.timer_outlined, size: 16,),
                                      Text(" ${vehicleDetails.updatedTime}", style: const TextStyle(fontSize: 12),)
                                        ],
                                      ),
                                    ],
                                  ),
                            const Divider(
                              thickness: 0.3,
                              color: Colors.black,
                            ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: scrollController,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Image.asset("assets/${vehicleDetails.vehicleType.toString().split('.').last}.png",width: 54,),
                                          const SizedBox(width: 16,),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(vehicleDetails.vehicleName ?? "N/A", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),),
                                              Text(vehicleDetails.isActive! ? "Active" : "Active", style: const TextStyle(fontSize: 12),),
                                            ],
                                          ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.local_gas_station_outlined, size: 18,),
                                              Text(":- ${vehicleDetails.vehicleFuelType}", style: const TextStyle(fontSize: 12),)
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(Icons.sim_card_outlined, size: 18,),
                                              Text(":- ${vehicleDetails.id}", style: const TextStyle(fontSize: 12),)
                                                ],
                                              ),
                                            ],
                                          ),

                                        ],
                                      ),
                                      const Gap(16),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined),
                                          const SizedBox(width: 8,),
                                          Expanded(
                                            child: Text(
                                              vehicleDetails.currentLocation ?? "",
                                              overflow: TextOverflow.visible,
                                              softWrap: true,
                                              style: const TextStyle(color: Colors.black, fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Gap(12),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text("${vehicleDetails.vehicleNewKm} Km"),
                                                Text("${vehicleDetails.vehicleKMLimit} Km"),
                                              ],
                                            ),
                                            LinearProgressIndicator(
                                              value: totalRun / limit, // total run/limit

                                              valueColor: limitColor[colorIndex],
                                            ),
                                          ],
                                        ),
                                      ),

                                      const Gap(12),
                                      Card(
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(3),
                                            topLeft: Radius.circular(3),
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAliasWithSaveLayer,
                                        color: Colors.white,
                                        elevation: 2,
                                        child: Column(
                                          children: [
                                            Container(
                                              height: 30,
                                              width: MediaQuery.of(context).size.width,
                                              decoration: const BoxDecoration(
                                                color: Color(0xff363333),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  "Vehicle Info",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                children: [
                                                  cardData(title: "Total Run", value: "${vehicleDetails.vehicleRunKM}", type:"Km"),
                                                  const SizedBox(
                                                    height: 24,
                                                    child: VerticalDivider(),
                                                  ),
                                                  cardData(title: "Limit Left", value: "${vehicleDetails.vehicleLimitLeft}", type: "Km"),
                                                  const SizedBox(
                                                    height: 24,
                                                    child: VerticalDivider(),
                                                  ),
                                                  cardData(title: "Limit", value: "${vehicleDetails.vehicleKMLimit}", type:"Km" )
                                                ],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: (){
                                                displayUpdateDialog(title: "Edit vehicle KM limit",id: vehicleDetails.id!);
                                              },
                                              child: const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text("Edit Limit", style: TextStyle(fontWeight: FontWeight.bold),),
                                                  Icon(Icons.arrow_forward_ios_outlined, size: 12,),
                                                ],
                                              ),
                                            ),
                                                const Gap(6)
                                          ],
                                        ),
                                      ),
                                      const Gap(12),
                                      Card(
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(3),
                                            topLeft: Radius.circular(3),
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAliasWithSaveLayer,
                                        color: Colors.white,
                                        elevation: 2,
                                        child: Column(
                                          children: [
                                            Container(
                                              height: 30,
                                              width: MediaQuery.of(context).size.width,
                                              decoration: const BoxDecoration(
                                                color: Color(0xff363333),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  "Speed Info",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                children: [
                                                  cardData(title: "Avg Speed", value: vehicleDetails.averageSpeed.toStringAsFixed(2), type:"Km/h"),
                                                  const SizedBox(
                                                    height: 24,
                                                    child: VerticalDivider(),
                                                  ),
                                                  cardData(title: "Max Speed", value: "${vehicleDetails.maxSpeed}", type: "Km/h"),
                                                  const SizedBox(
                                                    height: 24,
                                                    child: VerticalDivider(),
                                                  ),
                                                  cardData(title: "Last Speed", value: "${vehicleDetails.lastSpeed}", type:"Km/h" )
                                                ],
                                              ),
                                            ),

                                          ],
                                        ),
                                      ),
                                      const Gap(12),
                                      Card(
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(3),
                                            topLeft: Radius.circular(3),
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAliasWithSaveLayer,
                                        color: Colors.white,
                                        elevation: 2,
                                        child: Column(
                                          children: [
                                            Container(
                                              height: 30,
                                              width: MediaQuery.of(context).size.width,
                                              decoration: const BoxDecoration(
                                                color: Color(0xff363333),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  "Fuel Info",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,

                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                children: [
                                                  cardData(title: "Refueled on", value: "27/08/2024", type:""),
                                                  const SizedBox(
                                                    height: 24,
                                                    child: VerticalDivider(),
                                                  ),
                                                  cardData(title: "Mileage", value: "18", type: "kmpl"),

                                                ],
                                              ),
                                            ),

                                          ],
                                        ),
                                      ),
                                      const Gap(10),
                                      ElevatedButton(
                                          onPressed: (){
                                            showModalBottomSheet<void>(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return SizedBox(
                                                    height: MediaQuery.of(context).size.height/2,
                                                    width: MediaQuery.of(context).size.width,
                                                    child: Column(
                                                      children: [
                                                        const Gap(10),
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 16.0,vertical: 10),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              const Text("Past Locations", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                                                              GestureDetector(onTap: (){
                                                                Navigator.pop(context);
                                                              }, child: const Icon(Icons.close, color: Colors.black,))
                                                            ],
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: ListView.builder(
                                                            scrollDirection: Axis.vertical,
                                                            itemCount: data.length,
                                                            itemBuilder: (BuildContext context, int index) {
                                                              String key = data.keys.elementAt(index);
                                                              return Padding(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                                child: Card(
                                                                  elevation: 3,
                                                                  shadowColor: Colors.grey,
                                                                  child: ListTile(
                                                                    selectedTileColor: Colors.orange[100],
                                                                    title: Text(key,style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                                    trailing: Text("${data[key]['location']}" ,style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                        // ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
                                                      ],
                                                    ),
                                                  );
                                                }
                                            );
                                          },
                                        style: const ButtonStyle(
                                          backgroundColor: WidgetStatePropertyAll<Color>(Color(0xff363333)),
                                        ),
                                          child: const Text("View Past Locations",style: TextStyle(color: Colors.white70),),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

Widget vehicleDetailCard({required BuildContext context, required String title, required String valueTitle,required String value, required String type }) {
  return Card(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(3),
        topLeft: Radius.circular(3),
      ),
    ),
    clipBehavior: Clip.antiAliasWithSaveLayer,
    color: Colors.white,
    elevation: 2,
    child: Column(
      children: [
        Container(
          height: 30,
          width: MediaQuery.of(context).size.width,
          decoration: const BoxDecoration(
            color: Color(0xff363333),
          ),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              cardData(title: valueTitle, value: value, type:type),
              const SizedBox(
                height: 24,
                child: VerticalDivider(),
              ),
              cardData(title: valueTitle, value: value, type: type),
              const SizedBox(
                height: 24,
                child: VerticalDivider(),
              ),
              cardData(title: valueTitle, value: value, type:type )
            ],
          ),
        ),
      ],
    ),
  );
}

Widget cardData({required String title, required String value, required String type}) {
  return Column(
    children: [
      Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black),
      ),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
      Text(type),
    ],
  );
}

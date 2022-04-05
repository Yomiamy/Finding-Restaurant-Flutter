import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _markers = {
    Marker(
        position: LatLng(51.178883, -1.826215),
        markerId: MarkerId('1'),
        infoWindow: InfoWindow(title: "Stonehenge"),
        icon: BitmapDescriptor.defaultMarker),
    Marker(
        position: LatLng(41.890209, 12.492231),
        markerId: MarkerId('2'),
        infoWindow: InfoWindow(title: "Colosseum"),
        icon: BitmapDescriptor.defaultMarker),
    Marker(
        position: LatLng(36.106964, -112.112999),
        markerId: MarkerId('3'),
        infoWindow: InfoWindow(title: "Grand Canyon"),
        icon: BitmapDescriptor.defaultMarker)
  };

  CameraPosition? _mapCenterPos = null;
  GoogleMapController? _mapController = null;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('MapEx Page'),
        ),
        body: GoogleMap(
            initialCameraPosition:
                CameraPosition(target: LatLng(51.178883, -1.826215)),
            markers: this._markers,
            myLocationEnabled: true,
            onCameraMove: (position) {
              this._mapCenterPos = position;
            },
            onMapCreated: (controller) {
              this._mapController = controller;
            },
            onCameraIdle: () {
              setState(() {
                this._markers.add(Marker(
                    position: this._mapCenterPos!.target,
                    markerId: MarkerId('${this._markers.length + 1}'),
                    infoWindow:
                        InfoWindow(title: "Moved ${this._markers.length + 1}"),
                    icon: BitmapDescriptor.defaultMarker));
              });
            }));
  }
}

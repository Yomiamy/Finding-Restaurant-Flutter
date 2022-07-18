import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MapWidget extends StatefulWidget {
  final List<YelpRestaurantSummaryInfo> _summaryInfos;

  const MapWidget(this._summaryInfos);

  @override
  State<MapWidget> createState() => _MapPageState();
}

class _MapPageState extends State<MapWidget> {

  CameraPosition? _currentPos;
  GoogleMapController? _mapController;
  Marker? _myLocMarker;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();

    Iterable<Marker> ite = widget._summaryInfos.map((summaryInfo) => Marker(
        markerId: MarkerId(summaryInfo.id!),
        position: LatLng(summaryInfo.coordinates!.latitude!, summaryInfo.coordinates!.longitude!),
        infoWindow: InfoWindow(title: summaryInfo.name),
        icon: BitmapDescriptor.defaultMarker));
    this._markers = (){
      Set<Marker> markers = Set();

      markers.addAll(ite);
      return markers;
    }();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
        initialCameraPosition: CameraPosition(target: UIConstants.MAP_DEFAULT_LOCATION),
        markers: this._markers,
        myLocationEnabled: true,
        onCameraMove: (position) {
          this._currentPos = position;
        },
        onMapCreated: (controller) {
          this._mapController = controller;
        },
        onCameraIdle: () {
          if(_myLocMarker != null) {
            this._markers.remove(this._myLocMarker);
          }

          setState(() {
            this._myLocMarker = Marker(
                position: this._currentPos!.target,
                markerId: MarkerId(UIConstants.MAP_MY_LOCATION_MARK_ID),
                infoWindow: InfoWindow(title: AppLocalizations?.of(context)?.map_my_loc_title ?? ""),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow));

            this._markers.add(this._myLocMarker!);
          });
        });
  }
}

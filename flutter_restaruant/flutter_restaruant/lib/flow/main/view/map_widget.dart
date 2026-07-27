import 'package:flutter/material.dart';
import '../../../domain/entities/restaurant_entity.dart';
import '../../../utils/ui_constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../generated/l10n.dart';

class MapWidget extends StatefulWidget {
  final List<RestaurantEntity> _summaryInfos;

  const MapWidget(this._summaryInfos, {super.key});

  @override
  State<MapWidget> createState() => _MapPageState();
}

class _MapPageState extends State<MapWidget> {
  CameraPosition? _currentPos;
  Marker? _myLocMarker;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();

    Iterable<Marker> ite = widget._summaryInfos
        .where((summaryInfo) =>
            summaryInfo.id != null &&
            summaryInfo.coordinates?.latitude != null &&
            summaryInfo.coordinates?.longitude != null)
        .map((summaryInfo) => Marker(
            markerId: MarkerId(summaryInfo.id!),
            position: LatLng(summaryInfo.coordinates!.latitude!,
                summaryInfo.coordinates!.longitude!),
            infoWindow: InfoWindow(title: summaryInfo.name),
            icon: BitmapDescriptor.defaultMarker));
    _markers = () {
      Set<Marker> markers = {};

      markers.addAll(ite);
      return markers;
    }();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
        initialCameraPosition:
            const CameraPosition(target: UIConstants.mapDefaultLocation),
        markers: _markers,
        myLocationEnabled: true,
        onCameraMove: (position) {
          _currentPos = position;
        },
        onCameraIdle: () {
          if (_myLocMarker != null) {
            _markers.remove(_myLocMarker);
          }

          setState(() {
            _myLocMarker = Marker(
                position: _currentPos!.target,
                markerId: const MarkerId(UIConstants.mapMyLocationMarkId),
                infoWindow: InfoWindow(title: S.current.map_my_loc_title),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueYellow));

            _markers.add(_myLocMarker!);
          });
        });
  }
}

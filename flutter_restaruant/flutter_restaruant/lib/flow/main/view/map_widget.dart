import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../component/cell/main_page/main_page_barrel.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../../../features/foundation/constants/constants_barrel.dart';
import '../../../features/utils/utils_barrel.dart';
import '../../../generated/l10n.dart';
import '../../restaurant/view/view_barrel.dart';
import 'main_page.dart';

class MapWidget extends StatefulWidget {
  final List<RestaurantEntity> _summaryInfos;

  const MapWidget(this._summaryInfos, {super.key});

  @override
  State<MapWidget> createState() => _MapPageState();
}

class _MapPageState extends State<MapWidget> {
  CameraPosition? _centerPos;
  Marker? _centerLocMarker;
  Set<Marker> _markers = {};

  GoogleMapController? _mapController;
  late final PageController _pageController;
  List<RestaurantEntity> _validRestaurants = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _updateValidRestaurants();
    _updateMarkers();
  }

  @override
  void didUpdateWidget(covariant MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget._summaryInfos, oldWidget._summaryInfos)) {
      setState(() {
        _updateValidRestaurants();
        _selectedIndex = 0;
        _updateMarkers();
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _updateValidRestaurants() {
    _validRestaurants = widget._summaryInfos.where((info) {
      return info.id != null &&
          info.coordinates?.latitude != null &&
          info.coordinates?.longitude != null;
    }).toList();
  }

  void _updateMarkers() {
    Iterable<Marker> ite = _validRestaurants.asMap().entries.map((entry) {
      final index = entry.key;
      final summaryInfo = entry.value;

      return Marker(
        markerId: MarkerId(summaryInfo.id!),
        position: LatLng(
          summaryInfo.coordinates!.latitude!,
          summaryInfo.coordinates!.longitude!,
        ),
        infoWindow: InfoWindow(title: summaryInfo.name),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _selectedIndex == index
              ? BitmapDescriptor.hueBlue
              : BitmapDescriptor.hueRed,
        ),
        onTap: () {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          setState(() {
            _selectedIndex = index;
            _updateMarkers();
          });
        },
      );
    });

    _markers = {};
    _markers.addAll(ite);

    if (_centerLocMarker != null) {
      _markers.add(_centerLocMarker!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: UIConstants.mapDefaultLocation,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
          },
          markers: _markers,
          myLocationEnabled: true,
          onCameraMove: (position) {
            _centerPos = position;
          },
          onCameraIdle: () {
            setState(() {
              if (_centerLocMarker != null) {
                _markers.remove(_centerLocMarker);
              }

              _centerLocMarker = Marker(
                position: _centerPos!.target,
                markerId: const MarkerId(UIConstants.mapCenterLocMarkId),
                infoWindow: InfoWindow(title: S.current.map_my_loc_title),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueYellow,
                ),
              );

              _markers.add(_centerLocMarker!);
            });
          },
        ),
        if (_validRestaurants.isNotEmpty)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            height: 130,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _validRestaurants.length,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                  _updateMarkers();
                });
                final restaurant = _validRestaurants[index];
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(
                      restaurant.coordinates!.latitude!,
                      restaurant.coordinates!.longitude!,
                    ),
                  ),
                );
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: GestureDetector(
                    onTap: () {
                      final summaryInfo = _validRestaurants[index];
                      final arguments = Tuple2<RestaurantEntity, dynamic>(
                        summaryInfo,
                        null,
                      );
                      // Avoid duplicate push, use pushNamedAndRemoveUntil instead of push
                      // ignore: unawaited_futures
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        RestaurantDetailPage.routeName,
                        ModalRoute.withName(MainPage.routeName),
                        arguments: arguments,
                      );
                    },
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      elevation: 4.0,
                      child: RestaurantItemCell(
                        summaryInfo: _validRestaurants[index],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

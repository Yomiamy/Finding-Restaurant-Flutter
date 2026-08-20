import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fluster/fluster.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../../../features/foundation/constants/constants_barrel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../generated/l10n.dart';
import '../../../component/cell/main_page/restaurant_item_cell.dart';
import '../../../features/utils/utils_barrel.dart';
import '../../restaurant/view/view_barrel.dart';
import 'main_page.dart';
import '../model/map_marker_cluster.dart';
import '../../../features/utils/marker_generator.dart';

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

  Fluster<MapMarkerCluster>? _fluster;
  double _currentZoom = 13.0; // Default zoom
  final Map<int, BitmapDescriptor> _clusterMarkerCache = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _updateValidRestaurants();
    _initFluster();
    _updateClusters();
  }

  @override
  void didUpdateWidget(covariant MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget._summaryInfos, oldWidget._summaryInfos)) {
      setState(() {
        _updateValidRestaurants();
        _selectedIndex = 0;
        _initFluster();
        _updateClusters();
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

  void _initFluster() {
    final List<MapMarkerCluster> mapMarkers = [];
    for (int i = 0; i < _validRestaurants.length; i++) {
      final info = _validRestaurants[i];
      mapMarkers.add(MapMarkerCluster(
        restaurant: info,
        latitude: info.coordinates!.latitude!,
        longitude: info.coordinates!.longitude!,
      ));
    }

    _fluster = Fluster<MapMarkerCluster>(
      minZoom: 0,
      maxZoom: 21,
      radius: 150,
      extent: 2048,
      nodeSize: 64,
      points: mapMarkers,
      createCluster: (BaseCluster? cluster, double? lng, double? lat) {
        return MapMarkerCluster(
          latitude: lat!,
          longitude: lng!,
          isCluster: true,
          clusterId: cluster?.id,
          pointsSize: cluster?.pointsSize ?? 0,
          childMarkerId: cluster?.childMarkerId,
        );
      },
    );
  }

  Future<void> _updateClusters() async {
    if (_fluster == null) return;

    final List<MapMarkerCluster> clusters = _fluster!.clusters(
      [-180, -85, 180, 85],
      _currentZoom.toInt(),
    );

    final Set<Marker> newMarkers = {};

    for (var cluster in clusters) {
      if (cluster.isCluster == true) {
        BitmapDescriptor? icon = _clusterMarkerCache[cluster.pointsSize ?? 0];
        if (icon == null) {
          icon = await MarkerGenerator.getClusterMarker((cluster.pointsSize ?? 0));
          _clusterMarkerCache[cluster.pointsSize ?? 0] = icon;
        }

        newMarkers.add(
          Marker(
            markerId: MarkerId('cluster_${cluster.clusterId}'),
            position: LatLng(cluster.latitude!, cluster.longitude!),
            icon: icon, consumeTapEvents: true,
            onTap: () {
              if (_mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(cluster.latitude!, cluster.longitude!),
                    _currentZoom + 2,
                  ),
                );
              }
            },
          ),
        );
      } else {
        final info = cluster.restaurant!;
        final index = _validRestaurants.indexOf(info);
        newMarkers.add(
          Marker(
            markerId: MarkerId(info.id!),
            position: LatLng(
              info.coordinates!.latitude!,
              info.coordinates!.longitude!,
            ),
            infoWindow: InfoWindow(title: info.name),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _selectedIndex == index
                  ? BitmapDescriptor.hueBlue
                  : BitmapDescriptor.hueRed,
            ),
            onTap: () {
              if (index != -1) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                setState(() {
                  _selectedIndex = index;
                  _updateClusters();
                });
              }
            },
          ),
        );
      }
    }

    if (_centerLocMarker != null) {
      newMarkers.add(_centerLocMarker!);
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: UIConstants.mapDefaultLocation,
            zoom: 13.0,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
          },
          markers: _markers,
          myLocationEnabled: true,
          onCameraMove: (position) {
            _centerPos = position;
            _currentZoom = position.zoom;
          },
          onCameraIdle: () {
            setState(() {
              if (_centerLocMarker != null) {
                _markers.remove(_centerLocMarker);
              }

              _centerLocMarker = Marker(
                position: _centerPos?.target ?? UIConstants.mapDefaultLocation,
                markerId: const MarkerId(UIConstants.mapCenterLocMarkId),
                infoWindow: InfoWindow(title: S.current.map_my_loc_title),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueYellow,
                ),
              );

              _markers.add(_centerLocMarker!);
            });
            _updateClusters();
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
                  _updateClusters();
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

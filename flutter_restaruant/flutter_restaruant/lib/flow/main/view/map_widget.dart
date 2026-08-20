import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../../../features/foundation/constants/constants_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../generated/l10n.dart';
import '../../../component/cell/main_page/restaurant_item_cell.dart';
import '../../../features/utils/utils_barrel.dart';
import '../../restaurant/view/view_barrel.dart';
import 'main_page.dart';

class MapWidget extends StatefulWidget {
  final List<RestaurantEntity> _summaryInfos;

  const MapWidget(this._summaryInfos, {super.key});

  @override
  State<MapWidget> createState() => _MapPageState();
}

class _MapPageState extends State<MapWidget> {
  /// Sheet 收合／展開的高度佔比。收合時只露出一張卡片，展開時仍保留超過
  /// 半個畫面給地圖，避免使用者失去空間脈絡。
  static const double _sheetCollapsedSize = 0.22;
  static const double _sheetExpandedSize = 0.45;

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
          DraggableScrollableSheet(
            initialChildSize: _sheetCollapsedSize,
            minChildSize: _sheetCollapsedSize,
            maxChildSize: _sheetExpandedSize,
            // min 與 max 本身即是吸附點，snapSizes 只用於追加中間段，故留空。
            snap: true,
            // 預設 true 會讓 sheet 撐滿整個 Stack，把地圖的觸控事件吃掉。
            expand: false,
            builder: (context, scrollController) {
              // DraggableScrollableSheet 靠子項回報的垂直捲動量來拖曳，子項
              // 必須吃下它給的 controller，否則 sheet 會卡在 initialChildSize
              // 完全拖不動。這裡的內容是水平 PageView，因此外包一層垂直的
              // SingleChildScrollView 專門承接拖曳：垂直手勢歸 sheet，水平
              // 手勢仍由 PageView 自行處理。
              return SingleChildScrollView(
                controller: scrollController,
                child: SizedBox(
                  height: ThemeSize.size130,
                  // 隔離 carousel 重繪，避免帶動底層 Native Map View 一起 repaint。
                  child: RepaintBoundary(
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: ThemeSize.space4,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              final summaryInfo = _validRestaurants[index];
                              final arguments =
                                  Tuple2<RestaurantEntity, dynamic>(
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
                ),
              );
            },
          ),
      ],
    );
  }
}

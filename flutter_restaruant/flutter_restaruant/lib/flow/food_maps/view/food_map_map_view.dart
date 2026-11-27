import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../features/component/component_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';
import '../model/food_map_member_style.dart';
import 'food_map_detail_page.dart';

/// 共編美食地圖之地圖視圖（依成員色相標記 Marker 並與底部橫向卡片雙向聯動）。
class FoodMapMapView extends StatefulWidget {
  final List<FoodMapItemEntity> items;
  final void Function(FoodMapItemEntity item) onItemTap;

  const FoodMapMapView({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  /// 依推薦人 UID 決定性分配 Marker 色相並建立地圖標記集合。
  static Set<Marker> buildMarkers({
    required List<FoodMapItemEntity> items,
    required int selectedIndex,
    required void Function(int index) onSelect,
  }) {
    final markers = <Marker>{};
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final lat = item.restaurant.coordinates?.latitude;
      final lng = item.restaurant.coordinates?.longitude;
      if (lat == null || lng == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId(item.restaurantId),
          position: LatLng(lat, lng),
          zIndexInt: i == selectedIndex ? 2 : 1,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            FoodMapMemberStyle.markerHueForUid(item.addedByUid),
          ),
          infoWindow: InfoWindow(
            title: item.restaurant.name ?? '',
            snippet: S.current.food_maps_recommended_by(item.addedByName),
          ),
          onTap: () => onSelect(i),
        ),
      );
    }
    return markers;
  }

  /// 過濾出具備有效經緯度座標的餐廳項目。
  static List<FoodMapItemEntity> filterMappableItems(
    List<FoodMapItemEntity> items,
  ) {
    return items
        .where(
          (item) =>
              item.restaurant.coordinates?.latitude != null &&
              item.restaurant.coordinates?.longitude != null,
        )
        .toList();
  }

  @override
  State<FoodMapMapView> createState() => _FoodMapMapViewState();
}

class _FoodMapMapViewState extends State<FoodMapMapView> {
  late final PageController _pageController;
  GoogleMapController? _mapController;
  List<FoodMapItemEntity> _mappableItems = const [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _syncMappableItems();
  }

  @override
  void didUpdateWidget(covariant FoodMapMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.items, oldWidget.items)) {
      setState(() {
        _syncMappableItems();
        if (_selectedIndex >= _mappableItems.length) {
          _selectedIndex = 0;
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncMappableItems() {
    _mappableItems = FoodMapMapView.filterMappableItems(widget.items);
  }

  void _selectIndexFromMarker(int index) {
    setState(() => _selectedIndex = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onCarouselChanged(int index) {
    setState(() => _selectedIndex = index);
    final coords = _mappableItems[index].restaurant.coordinates;
    final lat = coords?.latitude;
    final lng = coords?.longitude;
    if (lat != null && lng != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mappableItems.isEmpty) {
      return EmptyDataWidget(
        title: S.current.food_maps_no_coordinates,
        icon: Icons.location_off_outlined,
      );
    }

    final firstCoords = _mappableItems.first.restaurant.coordinates;
    final initialTarget = LatLng(
      firstCoords?.latitude ?? 0,
      firstCoords?.longitude ?? 0,
    );
    final markers = FoodMapMapView.buildMarkers(
      items: _mappableItems,
      selectedIndex: _selectedIndex,
      onSelect: _selectIndexFromMarker,
    );

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialTarget,
            zoom: 13,
          ),
          onMapCreated: (controller) => _mapController = controller,
          markers: markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
        Positioned(
          left: ThemeSize.zero,
          right: ThemeSize.zero,
          bottom: ThemeSize.space20,
          height: ThemeSize.size130,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _mappableItems.length,
            onPageChanged: _onCarouselChanged,
            itemBuilder: (context, index) {
              final item = _mappableItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ThemeSize.space4,
                ),
                child: _FoodMapCarouselCard(
                  item: item,
                  onTap: () => widget.onItemTap(item),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FoodMapCarouselCard extends StatelessWidget {
  final FoodMapItemEntity item;
  final VoidCallback onTap;

  const _FoodMapCarouselCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(ThemeSize.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  FoodMapMemberAvatar(
                    uid: item.addedByUid,
                    name: item.addedByName,
                    radius: ThemeSize.space12,
                  ),
                  const SizedBox(width: ThemeSize.space8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.restaurant.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          S.current.food_maps_recommended_by(item.addedByName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (item.note.isNotEmpty)
                Text(
                  item.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
              Row(
                children: [
                  Icon(
                    Icons.thumb_up_outlined,
                    size: ThemeSize.size14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: ThemeSize.space4),
                  Text('${item.upvoteCount}', style: textTheme.labelSmall),
                  const SizedBox(width: ThemeSize.space12),
                  Icon(
                    Icons.thumb_down_outlined,
                    size: ThemeSize.size14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: ThemeSize.space4),
                  Text('${item.downvoteCount}', style: textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

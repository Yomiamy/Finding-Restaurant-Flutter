import 'package:fluster/fluster.dart';
import '../../../domain/entities/restaurant_entity.dart';

class MapMarkerCluster extends Clusterable {
  final RestaurantEntity? restaurant;

  MapMarkerCluster({
    this.restaurant,
    required double latitude,
    required double longitude,
    bool isCluster = false,
    int? clusterId,
    int pointsSize = 0,
    String? markerId,
    int? childMarkerId,
  }) : super(
          latitude: latitude,
          longitude: longitude,
          isCluster: isCluster,
          clusterId: clusterId,
          pointsSize: pointsSize,
          markerId: markerId ?? restaurant?.id ?? clusterId.toString(),
          childMarkerId: childMarkerId,
        );
}

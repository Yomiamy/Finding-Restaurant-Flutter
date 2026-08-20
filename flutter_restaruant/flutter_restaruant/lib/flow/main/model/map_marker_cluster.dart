import 'package:fluster/fluster.dart';
import '../../../domain/entities/restaurant_entity.dart';

class MapMarkerCluster extends Clusterable {
  final RestaurantEntity? restaurant;

  MapMarkerCluster({
    this.restaurant,
    required super.latitude,
    required super.longitude,
    super.isCluster = false,
    super.clusterId,
    super.pointsSize = 0,
    String? markerId,
    super.childMarkerId,
  }) : super(
          markerId: markerId ?? restaurant?.id ?? clusterId?.toString(),
        );
}

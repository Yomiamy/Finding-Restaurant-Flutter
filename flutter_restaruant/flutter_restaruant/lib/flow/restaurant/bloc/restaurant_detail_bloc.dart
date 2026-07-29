import 'package:bloc/bloc.dart';
import '../../../api/google_api_util.dart';
import '../../../domain/entities/restaurant_detail_entity.dart';
import '../../../domain/entities/restaurant_entity.dart';
import '../../../domain/entities/review_entity.dart';
import '../../../domain/repositories/restaurant_detail_repository.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

part 'restaurant_detail_event.dart';

part 'restaurant_detail_state.dart';

class RestaurantDetailBloc
    extends Bloc<RestaurantDetailEvent, RestaurantDetailState> {
  final RestaurantDetailRepository _detailRepository;

  RestaurantDetailBloc({required RestaurantDetailRepository repository})
      : _detailRepository = repository,
        super(const RestaurantDetailInitial()) {
    on<FetchDetailInfo>((event, emit) async {
      try {
        emit(const InProgress());

        final RestaurantDetailEntity detailInfo = await _detailRepository
            .fetchYelpRestaurantDetailInfo(event.id);
        final ReviewEntity reviewInfo = await _detailRepository
            .fetchYelpRestaurantReviewInfo(event.id);

        double lat = detailInfo.coordinates?.latitude ?? 0;
        double lng = detailInfo.coordinates?.longitude ?? 0;
        final String staticMapUrl =
            GoogleApiUtil.createStaticMapUrl(lat: lat, lng: lng);

        emit(Success(
            detailInfo: detailInfo,
            reviewInfo: reviewInfo,
            staticMapUrl: staticMapUrl));
      } on Exception catch (_) {
        emit(const Failure());
      }
    });

    on<ToggleFavor>((event, emit) async {
      try {
        emit(const InProgress());

        final RestaurantEntity updated =
            await _detailRepository.toggleFavor(event.summaryInfo);

        emit(ToggleFavorSuccess(summaryInfo: updated));
      } on Exception catch (_) {
        emit(const Failure());
      }
    });
  }
}

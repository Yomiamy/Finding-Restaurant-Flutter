import 'package:flutter_restaruant/data_layer/datasources/datasources_barrel.dart';
import 'package:flutter_restaruant/data_layer/repositories/favor_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFavorDataSource extends Mock implements FavorDataSource {}

void main() {
  late _MockFavorDataSource mockDataSource;
  late FavorRepo repo;

  setUp(() {
    mockDataSource = _MockFavorDataSource();
    repo = FavorRepo(favorDataSource: mockDataSource);
  });

  group('FavorRepo.isFavor Tests', () {
    test(
      'returns false without querying data source when id is empty',
      () async {
        expect(await repo.isFavor(''), isFalse);
        verifyNever(() => mockDataSource.fetchFavorIds());
      },
    );

    test(
      'returns true when id is in fetchFavorIds and false otherwise',
      () async {
        when(
          () => mockDataSource.fetchFavorIds(),
        ).thenAnswer((_) async => <String>{'biz-ichiran', 'biz-2'});

        expect(await repo.isFavor('biz-ichiran'), isTrue);
        expect(await repo.isFavor('biz-other'), isFalse);
        verify(() => mockDataSource.fetchFavorIds()).called(2);
      },
    );
  });
}

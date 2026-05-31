import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/app_database_provider.dart';
import 'package:phone/providers/settings_repository_provider.dart';

void main() {
  test('a Settings DB-hez kötött, működő repository-t ad', () async {
    // ARRANGE — in-memory DB az appDatabaseProvider mögé.
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    // ACT — a providerből kapott repón át írunk/olvasunk.
    final repository = container.read(settingsRepositoryProvider);
    await repository.writeActiveRaceId('race-1');

    // ASSERT — a valós DB-be ment, és visszaolvasható.
    expect(await repository.readActiveRaceId(), equals('race-1'));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:whereabouts/widgets/location_data.dart';

void main() {
  group('LocationData Tests', () {
    test('countryCodeToEmoji converts correctly', () {
      expect(LocationData.countryCodeToEmoji('MY'), '🇲🇾');
      expect(LocationData.countryCodeToEmoji('SG'), '🇸🇬');
      expect(LocationData.countryCodeToEmoji('US'), '🇺🇸');
      expect(LocationData.countryCodeToEmoji('KR'), '🇰🇷');
      expect(LocationData.countryCodeToEmoji('JP'), '🇯🇵');
    });

    test('cleanText removes flag emojis', () {
      expect(LocationData.cleanText('🇲🇾 Malaysia'), 'Malaysia');
      expect(LocationData.cleanText('🇰🇷 South Korea'), 'South Korea');
      expect(LocationData.cleanText('United States'), 'United States');
    });

    test('findCountry finds standard and newly supported countries', () {
      final my = LocationData.findCountry('Malaysia');
      expect(my, isNotNull);
      expect(my!.code, 'MY');
      expect(my.states, contains('Penang'));

      // South Korea was missing in csc_picker_plus
      final kr = LocationData.findCountry('South Korea');
      expect(kr, isNotNull);
      expect(kr!.code, 'KR');
      expect(kr.states, contains('Seoul'));

      // Hong Kong and Taiwan
      final hk = LocationData.findCountry('Hong Kong');
      expect(hk, isNotNull);
      expect(hk!.code, 'HK');

      final tw = LocationData.findCountry('Taiwan');
      expect(tw, isNotNull);
      expect(tw!.code, 'TW');
    });

    test('searchCountries filters correctly', () {
      final results = LocationData.searchCountries('korea');
      expect(results.any((c) => c.name == 'South Korea'), isTrue);

      final malay = LocationData.searchCountries('Malay');
      expect(malay.first.name, 'Malaysia');
    });

    test('searchStates returns states for known countries', () {
      final states = LocationData.searchStates('Malaysia', 'pen');
      expect(states, contains('Penang'));

      final krStates = LocationData.searchStates('South Korea', 'seo');
      expect(krStates, contains('Seoul'));
    });

    test('searchLocations finds state directly and prioritizes it (e.g. Bali -> Indonesia, Bali)', () {
      final matches = LocationData.searchLocations('bali');
      expect(matches, isNotEmpty);
      final baliMatch = matches.first;
      expect(baliMatch.isState, isTrue);
      expect(baliMatch.stateName, equals('Bali'));
      expect(baliMatch.countryName, equals('Indonesia'));
      expect(baliMatch.flag, equals('🇮🇩'));
      expect(baliMatch.displayTitle, equals('Bali, Indonesia'));
      expect(baliMatch.displaySubtitle, equals('State / Region in Indonesia'));
    });

    test('searchLocations finds Penang, Tokyo, and Seoul correctly', () {
      final penang = LocationData.searchLocations('penang');
      expect(penang.any((m) => m.stateName == 'Penang' && m.countryName == 'Malaysia'), isTrue);

      final tokyo = LocationData.searchLocations('tokyo');
      expect(tokyo.any((m) => m.stateName == 'Tokyo' && m.countryName == 'Japan'), isTrue);

      final seoul = LocationData.searchLocations('seoul');
      expect(seoul.any((m) => m.stateName == 'Seoul' && m.countryName == 'South Korea'), isTrue);
    });

    test('searchLocations handles comma-separated inputs', () {
      final matches = LocationData.searchLocations('Bali, Indonesia');
      expect(matches, isNotEmpty);
      expect(matches.first.stateName, equals('Bali'));
      expect(matches.first.countryName, equals('Indonesia'));
    });

    test('resolveLocation resolves both country and state properly', () {
      final r1 = LocationData.resolveLocation('Bali, Indonesia');
      expect(r1, isNotNull);
      expect(r1!.country, equals('Indonesia'));
      expect(r1.state, equals('Bali'));

      final r2 = LocationData.resolveLocation('Indonesia, Bali');
      expect(r2, isNotNull);
      expect(r2!.country, equals('Indonesia'));
      expect(r2.state, equals('Bali'));

      final r3 = LocationData.resolveLocation('Malaysia');
      expect(r3, isNotNull);
      expect(r3!.country, equals('Malaysia'));
      expect(r3.state, isNull);
    });
  });
}

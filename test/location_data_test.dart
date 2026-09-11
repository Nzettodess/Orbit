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
  });
}

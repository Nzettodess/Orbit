import 'location_data.dart';

/// Database of standard countries, flags, codes, and subdivisions
/// Strictly under 500 lines (Hard limit: 500 lines)
final List<CountryInfo> kWorldCountries = [
  CountryInfo(
    name: 'Malaysia',
    code: 'MY',
    flag: '🇲🇾',
    states: [
      'Johor', 'Kedah', 'Kelantan', 'Kuala Lumpur', 'Labuan', 'Melaka',
      'Negeri Sembilan', 'Pahang', 'Penang', 'Perak', 'Perlis', 'Putrajaya',
      'Sabah', 'Sarawak', 'Selangor', 'Terengganu'
    ],
  ),
  CountryInfo(
    name: 'Singapore',
    code: 'SG',
    flag: '🇸🇬',
    states: ['Central', 'East', 'North', 'North-East', 'West'],
  ),
  CountryInfo(
    name: 'Indonesia',
    code: 'ID',
    flag: '🇮🇩',
    states: [
      'Bali', 'Jakarta', 'Banten', 'Central Java', 'East Java', 'West Java',
      'Yogyakarta', 'North Sumatra', 'South Sulawesi', 'Riau', 'Lombok', 'Batam'
    ],
  ),
  CountryInfo(
    name: 'Thailand',
    code: 'TH',
    flag: '🇹🇭',
    states: [
      'Bangkok', 'Chiang Mai', 'Phuket', 'Chonburi', 'Krabi',
      'Surat Thani', 'Nonthaburi', 'Pathum Thani', 'Nakhon Ratchasima'
    ],
  ),
  CountryInfo(
    name: 'South Korea',
    code: 'KR',
    flag: '🇰🇷',
    states: [
      'Seoul', 'Busan', 'Daegu', 'Incheon', 'Gwangju', 'Daejeon',
      'Ulsan', 'Sejong', 'Gyeonggi', 'Gangwon', 'North Chungcheong',
      'South Chungcheong', 'North Jeolla', 'South Jeolla',
      'North Gyeongsang', 'South Gyeongsang', 'Jeju'
    ],
  ),
  CountryInfo(
    name: 'Japan',
    code: 'JP',
    flag: '🇯🇵',
    states: [
      'Tokyo', 'Osaka', 'Kyoto', 'Hokkaido', 'Aichi', 'Fukuoka',
      'Kanagawa', 'Saitama', 'Chiba', 'Hyogo', 'Hiroshima', 'Okinawa'
    ],
  ),
  CountryInfo(
    name: 'United States',
    code: 'US',
    flag: '🇺🇸',
    states: [
      'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
      'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
      'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
      'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
      'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
      'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
      'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon',
      'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
      'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
      'West Virginia', 'Wisconsin', 'Wyoming', 'Washington D.C.', 'Puerto Rico'
    ],
  ),
  CountryInfo(
    name: 'United Kingdom',
    code: 'GB',
    flag: '🇬🇧',
    states: [
      'England', 'Scotland', 'Wales', 'Northern Ireland',
      'Greater London', 'Greater Manchester', 'West Midlands'
    ],
  ),
  CountryInfo(
    name: 'Australia',
    code: 'AU',
    flag: '🇦🇺',
    states: [
      'Australian Capital Territory', 'New South Wales', 'Northern Territory',
      'Queensland', 'South Australia', 'Tasmania', 'Victoria', 'Western Australia'
    ],
  ),
  CountryInfo(
    name: 'Canada',
    code: 'CA',
    flag: '🇨🇦',
    states: [
      'Alberta', 'British Columbia', 'Manitoba', 'New Brunswick',
      'Newfoundland and Labrador', 'Northwest Territories', 'Nova Scotia',
      'Nunavut', 'Ontario', 'Prince Edward Island', 'Quebec',
      'Saskatchewan', 'Yukon'
    ],
  ),
  CountryInfo(
    name: 'China',
    code: 'CN',
    flag: '🇨🇳',
    states: [
      'Beijing', 'Shanghai', 'Guangdong', 'Zhejiang', 'Jiangsu', 'Sichuan',
      'Shandong', 'Fujian', 'Hubei', 'Hunan', 'Shaanxi', 'Tianjin', 'Chongqing'
    ],
  ),
  CountryInfo(
    name: 'Hong Kong',
    code: 'HK',
    flag: '🇭🇰',
    states: ['Hong Kong Island', 'Kowloon', 'New Territories'],
  ),
  CountryInfo(
    name: 'Taiwan',
    code: 'TW',
    flag: '🇹🇼',
    states: [
      'Taipei', 'New Taipei', 'Taoyuan', 'Taichung', 'Tainan', 'Kaohsiung',
      'Hsinchu', 'Keelung', 'Chiayi', 'Yilan', 'Hualien', 'Taitung'
    ],
  ),
  CountryInfo(
    name: 'Philippines',
    code: 'PH',
    flag: '🇵🇭',
    states: [
      'Metro Manila', 'Cebu', 'Davao', 'Cavite', 'Laguna',
      'Pampanga', 'Iloilo', 'Batangas', 'Rizal', 'Bulacan'
    ],
  ),
  CountryInfo(
    name: 'Vietnam',
    code: 'VN',
    flag: '🇻🇳',
    states: [
      'Hanoi', 'Ho Chi Minh City', 'Da Nang', 'Hai Phong', 'Can Tho',
      'Quang Ninh', 'Khanh Hoa', 'Thua Thien Hue', 'Binh Duong'
    ],
  ),
  CountryInfo(
    name: 'India',
    code: 'IN',
    flag: '🇮🇳',
    states: [
      'Delhi', 'Maharashtra', 'Karnataka', 'Tamil Nadu', 'Telangana',
      'Uttar Pradesh', 'Gujarat', 'West Bengal', 'Kerala', 'Rajasthan',
      'Punjab', 'Haryana', 'Madhya Pradesh', 'Goa'
    ],
  ),
  CountryInfo(
    name: 'Germany',
    code: 'DE',
    flag: '🇩🇪',
    states: [
      'Baden-Württemberg', 'Bavaria', 'Berlin', 'Brandenburg', 'Bremen',
      'Hamburg', 'Hesse', 'Lower Saxony', 'North Rhine-Westphalia',
      'Rhineland-Palatinate', 'Saxony', 'Schleswig-Holstein'
    ],
  ),
  CountryInfo(
    name: 'France',
    code: 'FR',
    flag: '🇫🇷',
    states: [
      'Île-de-France', 'Auvergne-Rhône-Alpes', 'Nouvelle-Aquitaine',
      'Occitanie', 'Provence-Alpes-Côte d\'Azur', 'Hauts-de-France'
    ],
  ),
  CountryInfo(
    name: 'Netherlands',
    code: 'NL',
    flag: '🇳🇱',
    states: [
      'North Holland', 'South Holland', 'Utrecht', 'North Brabant',
      'Gelderland', 'Overijssel', 'Limburg', 'Friesland', 'Groningen'
    ],
  ),
  CountryInfo(
    name: 'New Zealand',
    code: 'NZ',
    flag: '🇳🇿',
    states: [
      'Auckland', 'Bay of Plenty', 'Canterbury', 'Gisborne', 'Hawke\'s Bay',
      'Manawatū-Whanganui', 'Marlborough', 'Nelson', 'Northland', 'Otago',
      'Southland', 'Taranaki', 'Tasman', 'Waikato', 'Wellington', 'West Coast'
    ],
  ),
  CountryInfo(
    name: 'Italy',
    code: 'IT',
    flag: '🇮🇹',
    states: [
      'Rome', 'Milan', 'Venice', 'Florence', 'Naples', 'Turin',
      'Lombardy', 'Lazio', 'Veneto', 'Tuscany', 'Piedmont', 'Sicily', 'Sardinia'
    ],
  ),
  CountryInfo(
    name: 'Spain',
    code: 'ES',
    flag: '🇪🇸',
    states: [
      'Barcelona', 'Madrid', 'Andalusia', 'Catalonia', 'Valencia', 'Galicia',
      'Balearic Islands', 'Canary Islands', 'Basque Country', 'Castile and León'
    ],
  ),
  CountryInfo(
    name: 'Switzerland',
    code: 'CH',
    flag: '🇨🇭',
    states: ['Zurich', 'Geneva', 'Bern', 'Basel-Stadt', 'Vaud', 'Lucerne'],
  ),
  CountryInfo(
    name: 'United Arab Emirates',
    code: 'AE',
    flag: '🇦🇪',
    states: ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman', 'Ras Al Khaimah', 'Fujairah', 'Umm Al Quwain'],
  ),
  CountryInfo(
    name: 'Qatar',
    code: 'QA',
    flag: '🇶🇦',
    states: ['Doha', 'Al Rayyan', 'Al Wakrah', 'Al Khor'],
  ),
  CountryInfo(
    name: 'Saudi Arabia',
    code: 'SA',
    flag: '🇸🇦',
    states: ['Riyadh', 'Makkah', 'Madinah', 'Eastern Province', 'Asir'],
  ),
  CountryInfo(
    name: 'Turkey',
    code: 'TR',
    flag: '🇹🇷',
    states: ['Istanbul', 'Ankara', 'Izmir', 'Antalya', 'Bursa', 'Mugla'],
  ),
  CountryInfo(name: 'Afghanistan', code: 'AF', flag: '🇦🇫'),
  CountryInfo(name: 'Albania', code: 'AL', flag: '🇦🇱'),
  CountryInfo(name: 'Algeria', code: 'DZ', flag: '🇩🇿'),
  CountryInfo(name: 'Andorra', code: 'AD', flag: '🇦🇩'),
  CountryInfo(name: 'Angola', code: 'AO', flag: '🇦🇴'),
  CountryInfo(name: 'Argentina', code: 'AR', flag: '🇦🇷'),
  CountryInfo(name: 'Armenia', code: 'AM', flag: '🇦🇲'),
  CountryInfo(name: 'Azerbaijan', code: 'AZ', flag: '🇦🇿'),
  CountryInfo(name: 'Bahamas', code: 'BS', flag: '🇧🇸'),
  CountryInfo(name: 'Bahrain', code: 'BH', flag: '🇧🇭'),
  CountryInfo(name: 'Bangladesh', code: 'BD', flag: '🇧🇩'),
  CountryInfo(name: 'Barbados', code: 'BB', flag: '🇧🇧'),
  CountryInfo(name: 'Belarus', code: 'BY', flag: '🇧🇾'),
  CountryInfo(name: 'Belize', code: 'BZ', flag: '🇧🇿'),
  CountryInfo(name: 'Benin', code: 'BJ', flag: '🇧🇯'),
  CountryInfo(name: 'Bhutan', code: 'BT', flag: '🇧🇹'),
  CountryInfo(name: 'Bolivia', code: 'BO', flag: '🇧🇴'),
  CountryInfo(name: 'Bosnia and Herzegovina', code: 'BA', flag: '🇧🇦'),
  CountryInfo(name: 'Botswana', code: 'BW', flag: '🇧🇼'),
  CountryInfo(name: 'Brunei', code: 'BN', flag: '🇧🇳'),
  CountryInfo(name: 'Bulgaria', code: 'BG', flag: '🇧🇬'),
  CountryInfo(name: 'Cambodia', code: 'KH', flag: '🇰🇭'),
  CountryInfo(name: 'Cameroon', code: 'CM', flag: '🇨🇲'),
  CountryInfo(name: 'Chile', code: 'CL', flag: '🇨🇱'),
  CountryInfo(name: 'Colombia', code: 'CO', flag: '🇨🇴'),
  CountryInfo(name: 'Costa Rica', code: 'CR', flag: '🇨🇷'),
  CountryInfo(name: 'Croatia', code: 'HR', flag: '🇭🇷'),
  CountryInfo(name: 'Cuba', code: 'CU', flag: '🇨🇺'),
  CountryInfo(name: 'Cyprus', code: 'CY', flag: '🇨🇾'),
  CountryInfo(name: 'Czech Republic', code: 'CZ', flag: '🇨🇿'),
  CountryInfo(name: 'Dominican Republic', code: 'DO', flag: '🇩🇴'),
  CountryInfo(name: 'Ecuador', code: 'EC', flag: '🇪🇨'),
  CountryInfo(name: 'Egypt', code: 'EG', flag: '🇪🇬'),
  CountryInfo(name: 'Estonia', code: 'EE', flag: '🇪🇪'),
  CountryInfo(name: 'Ethiopia', code: 'ET', flag: '🇪🇹'),
  CountryInfo(name: 'Fiji', code: 'FJ', flag: '🇫🇯'),
  CountryInfo(name: 'Finland', code: 'FI', flag: '🇫🇮'),
  CountryInfo(name: 'Georgia', code: 'GE', flag: '🇬🇪'),
  CountryInfo(name: 'Ghana', code: 'GH', flag: '🇬🇭'),
  CountryInfo(name: 'Greece', code: 'GR', flag: '🇬🇷'),
  CountryInfo(name: 'Guatemala', code: 'GT', flag: '🇬🇹'),
  CountryInfo(name: 'Honduras', code: 'HN', flag: '🇭🇳'),
  CountryInfo(name: 'Hungary', code: 'HU', flag: '🇭🇺'),
  CountryInfo(name: 'Iceland', code: 'IS', flag: '🇮🇸'),
  CountryInfo(name: 'Iran', code: 'IR', flag: '🇮🇷'),
  CountryInfo(name: 'Iraq', code: 'IQ', flag: '🇮🇶'),
  CountryInfo(name: 'Ireland', code: 'IE', flag: '🇮🇪'),
  CountryInfo(name: 'Israel', code: 'IL', flag: '🇮🇱'),
  CountryInfo(name: 'Jamaica', code: 'JM', flag: '🇯🇲'),
  CountryInfo(name: 'Jordan', code: 'JO', flag: '🇯🇴'),
  CountryInfo(name: 'Kazakhstan', code: 'KZ', flag: '🇰🇿'),
  CountryInfo(name: 'Kenya', code: 'KE', flag: '🇰🇪'),
  CountryInfo(name: 'Kuwait', code: 'KW', flag: '🇰🇼'),
  CountryInfo(name: 'Laos', code: 'LA', flag: '🇱🇦'),
  CountryInfo(name: 'Latvia', code: 'LV', flag: '🇱🇻'),
  CountryInfo(name: 'Lebanon', code: 'LB', flag: '🇱🇧'),
  CountryInfo(name: 'Lithuania', code: 'LT', flag: '🇱🇹'),
  CountryInfo(name: 'Luxembourg', code: 'LU', flag: '🇱🇺'),
  CountryInfo(name: 'Macau', code: 'MO', flag: '🇲🇴'),
  CountryInfo(name: 'Maldives', code: 'MV', flag: '🇲🇻'),
  CountryInfo(name: 'Malta', code: 'MT', flag: '🇲🇹'),
  CountryInfo(name: 'Mauritius', code: 'MU', flag: '🇲🇺'),
  CountryInfo(name: 'Mexico', code: 'MX', flag: '🇲🇽'),
  CountryInfo(name: 'Monaco', code: 'MC', flag: '🇲🇨'),
  CountryInfo(name: 'Mongolia', code: 'MN', flag: '🇲🇳'),
  CountryInfo(name: 'Morocco', code: 'MA', flag: '🇲🇦'),
  CountryInfo(name: 'Myanmar', code: 'MM', flag: '🇲🇲'),
  CountryInfo(name: 'Nepal', code: 'NP', flag: '🇳🇵'),
  CountryInfo(name: 'Nigeria', code: 'NG', flag: '🇳🇬'),
  CountryInfo(name: 'North Macedonia', code: 'MK', flag: '🇲🇰'),
  CountryInfo(name: 'Norway', code: 'NO', flag: '🇳🇴'),
  CountryInfo(name: 'Oman', code: 'OM', flag: '🇴🇲'),
  CountryInfo(name: 'Pakistan', code: 'PK', flag: '🇵🇰'),
  CountryInfo(name: 'Panama', code: 'PA', flag: '🇵🇦'),
  CountryInfo(name: 'Paraguay', code: 'PY', flag: '🇵🇾'),
  CountryInfo(name: 'Peru', code: 'PE', flag: '🇵🇪'),
  CountryInfo(name: 'Poland', code: 'PL', flag: '🇵🇱'),
  CountryInfo(name: 'Portugal', code: 'PT', flag: '🇵🇹'),
  CountryInfo(name: 'Romania', code: 'RO', flag: '🇷🇴'),
  CountryInfo(name: 'Russia', code: 'RU', flag: '🇷🇺'),
  CountryInfo(name: 'Rwanda', code: 'RW', flag: '🇷🇼'),
  CountryInfo(name: 'Serbia', code: 'RS', flag: '🇷🇸'),
  CountryInfo(name: 'Slovakia', code: 'SK', flag: '🇸🇰'),
  CountryInfo(name: 'Slovenia', code: 'SI', flag: '🇸🇮'),
  CountryInfo(name: 'South Africa', code: 'ZA', flag: '🇿🇦'),
  CountryInfo(name: 'Sri Lanka', code: 'LK', flag: '🇱🇰'),
  CountryInfo(name: 'Sweden', code: 'SE', flag: '🇸🇪'),
  CountryInfo(name: 'Ukraine', code: 'UA', flag: '🇺🇦'),
  CountryInfo(name: 'Uruguay', code: 'UY', flag: '🇺🇾'),
  CountryInfo(name: 'Uzbekistan', code: 'UZ', flag: '🇺🇿'),
  CountryInfo(name: 'Vatican City', code: 'VA', flag: '🇻🇦'),
  CountryInfo(name: 'Venezuela', code: 'VE', flag: '🇻🇪'),
  CountryInfo(name: 'Zimbabwe', code: 'ZW', flag: '🇿🇼'),
];

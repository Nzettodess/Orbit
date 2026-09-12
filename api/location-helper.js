// Smart location normalization and mapping for Google Flights queries
// Ensures free-text queries (e.g. "Penang (PEN)", "PEN", "Malaysia", "Tokyo (HND)")
// reliably resolve to optimal query terms recognized by Google Flights.
// Strictly under 500 lines (Hard limit: 500 lines)

export const IATA_TO_CITY = {
  // Malaysia
  KUL: 'Kuala Lumpur',
  PEN: 'Penang',
  BKI: 'Kota Kinabalu',
  JHB: 'Johor Bahru',
  KCH: 'Kuching',
  LGK: 'Langkawi',
  SZB: 'Subang',
  MYY: 'Miri',
  SBW: 'Sibu',
  TWU: 'Tawau',
  BTU: 'Bintulu',
  KBR: 'Kota Bharu',
  TGG: 'Kuala Terengganu',
  AOR: 'Alor Setar',
  IPH: 'Ipoh',

  // Singapore
  SIN: 'Singapore',
  XSP: 'Singapore',

  // Thailand
  BKK: 'Bangkok',
  DMK: 'Bangkok',
  HKT: 'Phuket',
  CNX: 'Chiang Mai',
  KBV: 'Krabi',
  USM: 'Koh Samui',

  // Indonesia
  DPS: 'Bali',
  CGK: 'Jakarta',
  SUB: 'Surabaya',
  KNO: 'Medan',
  JOG: 'Yogyakarta',
  YIA: 'Yogyakarta',
  BDO: 'Bandung',

  // Vietnam & Philippines
  SGN: 'Ho Chi Minh City',
  HAN: 'Hanoi',
  DAD: 'Da Nang',
  MNL: 'Manila',
  CEB: 'Cebu',
  CRK: 'Clark',

  // East Asia
  HND: 'Tokyo',
  NRT: 'Tokyo',
  KIX: 'Osaka',
  ITM: 'Osaka',
  FUK: 'Fukuoka',
  CTS: 'Sapporo',
  OKA: 'Okinawa',
  ICN: 'Seoul',
  GMP: 'Seoul',
  PUS: 'Busan',
  CJU: 'Jeju',
  TPE: 'Taipei',
  TSA: 'Taipei',
  KHH: 'Kaohsiung',
  HKG: 'Hong Kong',
  MFM: 'Macau',
  PVG: 'Shanghai',
  SHA: 'Shanghai',
  PEK: 'Beijing',
  PKX: 'Beijing',
  CAN: 'Guangzhou',
  SZX: 'Shenzhen',
  CTU: 'Chengdu',

  // Australia & New Zealand
  SYD: 'Sydney',
  MEL: 'Melbourne',
  BNE: 'Brisbane',
  PER: 'Perth',
  ADL: 'Adelaide',
  OOL: 'Gold Coast',
  AKL: 'Auckland',
  CHC: 'Christchurch',
  WLG: 'Wellington',

  // Europe
  LHR: 'London',
  LGW: 'London',
  STN: 'London',
  CDG: 'Paris',
  ORY: 'Paris',
  AMS: 'Amsterdam',
  FRA: 'Frankfurt',
  MUC: 'Munich',
  ZRH: 'Zurich',
  GVA: 'Geneva',
  FCO: 'Rome',
  MXP: 'Milan',
  BCN: 'Barcelona',
  MAD: 'Madrid',
  VIE: 'Vienna',
  BRU: 'Brussels',
  CPH: 'Copenhagen',
  ARN: 'Stockholm',
  OSL: 'Oslo',
  HEL: 'Helsinki',
  DUB: 'Dublin',
  ATH: 'Athens',
  IST: 'Istanbul',
  SAW: 'Istanbul',

  // Middle East
  DXB: 'Dubai',
  DWC: 'Dubai',
  AUH: 'Abu Dhabi',
  DOH: 'Doha',
  RUH: 'Riyadh',
  JED: 'Jeddah',

  // North America
  JFK: 'New York',
  EWR: 'New York',
  LGA: 'New York',
  LAX: 'Los Angeles',
  SFO: 'San Francisco',
  ORD: 'Chicago',
  MIA: 'Miami',
  SEA: 'Seattle',
  BOS: 'Boston',
  YVR: 'Vancouver',
  YYZ: 'Toronto',
  YUL: 'Montreal',
};

export const COUNTRY_TO_HUB = {
  malaysia: 'Kuala Lumpur',
  singapore: 'Singapore',
  thailand: 'Bangkok',
  indonesia: 'Jakarta',
  japan: 'Tokyo',
  korea: 'Seoul',
  'south korea': 'Seoul',
  taiwan: 'Taipei',
  'hong kong': 'Hong Kong',
  vietnam: 'Ho Chi Minh City',
  philippines: 'Manila',
  australia: 'Sydney',
  'new zealand': 'Auckland',
  uk: 'London',
  'united kingdom': 'London',
  england: 'London',
  france: 'Paris',
  germany: 'Frankfurt',
  italy: 'Rome',
  spain: 'Madrid',
  netherlands: 'Amsterdam',
  switzerland: 'Zurich',
  turkey: 'Istanbul',
  uae: 'Dubai',
  'united arab emirates': 'Dubai',
  qatar: 'Doha',
  usa: 'New York',
  'united states': 'New York',
  canada: 'Toronto',
  china: 'Shanghai',
};

/**
 * Normalizes user-entered location strings into the most reliable query term for Google Flights.
 * Strips parentheses, extracts known IATA codes into city names, and maps countries to main hubs.
 * Examples:
 *   "Penang (PEN)" -> "Penang"
 *   "PEN" -> "Penang"
 *   "Malaysia, Penang" -> "Penang"
 *   "Malaysia" -> "Kuala Lumpur"
 *   "Singapore (SIN)" -> "Singapore"
 *   "Tokyo (HND)" -> "Tokyo"
 */
export function normalizeLocation(raw) {
  if (!raw || typeof raw !== 'string') return '';
  let str = raw.trim();

  // Strip emoji characters
  str = str.replace(/[\u{1F300}-\u{1F6FF}|\u{1F1E6}-\u{1F1FF}|\u{2700}-\u{27BF}]/gu, '').trim();

  // Match "City (IATA)" format e.g. "Penang (PEN)" or "Tokyo (HND)"
  const withCodeMatch = str.match(/^(.+?)\s*\(([A-Z0-9]{3})\)$/i);
  if (withCodeMatch) {
    const cityName = withCodeMatch[1].trim();
    const code = withCodeMatch[2].toUpperCase();
    if (IATA_TO_CITY[code]) return IATA_TO_CITY[code];
    return cityName;
  }

  // Standalone 3-letter IATA code e.g. "PEN", "KUL", "NRT"
  const upper = str.toUpperCase();
  if (IATA_TO_CITY[upper]) {
    return IATA_TO_CITY[upper];
  }

  // Comma or bullet separated location e.g. "Penang, Malaysia" or "Tokyo, Japan"
  if (str.includes(',') || str.includes('•') || str.includes('-')) {
    const parts = str.split(/[,•-]/).map(s => s.trim()).filter(Boolean);
    // Prefer the most specific city/state part that isn't a generic country
    for (const p of parts) {
      const pUpper = p.toUpperCase();
      if (IATA_TO_CITY[pUpper]) return IATA_TO_CITY[pUpper];
      const pLower = p.toLowerCase();
      if (!COUNTRY_TO_HUB[pLower] && p.length > 1) {
        return p;
      }
    }
  }

  // Country name e.g. "Malaysia" -> "Kuala Lumpur"
  const lower = str.toLowerCase();
  if (COUNTRY_TO_HUB[lower]) {
    return COUNTRY_TO_HUB[lower];
  }

  // Strip any remaining brackets or parentheses
  return str.replace(/[()[\]{}]/g, '').trim();
}

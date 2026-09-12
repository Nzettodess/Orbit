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

  // 1. Explicit IATA code in parentheses e.g. "Penang (PEN)", "Subang (SZB)", "Tokyo (HND)"
  const withCodeMatch = str.match(/^(.+?)\s*\(([A-Z0-9]{3})\)$/i);
  if (withCodeMatch) {
    return withCodeMatch[2].toUpperCase();
  }

  // 2. Standalone 3-letter IATA code e.g. "PEN", "SZB", "KUL", "NRT"
  if (/^[A-Za-z0-9]{3}$/.test(str)) {
    return str.toUpperCase();
  }

  // 3. Known special secondary/regional airport cities
  const lower = str.toLowerCase();
  if (lower === 'subang') return 'SZB';
  if (lower === 'penang') return 'PEN';

  // 4. Comma or bullet separated location e.g. "Penang (PEN), Malaysia" or "Penang, Malaysia"
  if (str.includes(',') || str.includes('•') || str.includes('-')) {
    const parts = str.split(/[,•-]/).map(s => s.trim()).filter(Boolean);
    for (const p of parts) {
      const codeMatch = p.match(/\(([A-Z0-9]{3})\)/i);
      if (codeMatch) return codeMatch[1].toUpperCase();
      if (/^[A-Za-z0-9]{3}$/.test(p)) return p.toUpperCase();
      const pLower = p.toLowerCase();
      if (pLower === 'subang') return 'SZB';
      if (pLower === 'penang') return 'PEN';
      if (!COUNTRY_TO_HUB[pLower] && p.length > 1) {
        return p;
      }
    }
  }

  // 5. Country name e.g. "Malaysia" -> "Kuala Lumpur"
  if (COUNTRY_TO_HUB[lower]) {
    return COUNTRY_TO_HUB[lower];
  }

  // Strip any remaining brackets or parentheses
  return str.replace(/[()[\]{}]/g, '').trim();
}

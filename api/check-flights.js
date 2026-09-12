// Vercel Serverless Function: Google Flights Query & Parser
// Strictly under 500 lines (Hard limit: 500 lines)
import { normalizeLocation } from './location-helper.js';

function formatTime(timeArr) {
  if (!timeArr || timeArr.length < 1) return '';
  const h = timeArr[0];
  const m = timeArr[1] || 0;
  const ampm = h >= 12 ? 'PM' : 'AM';
  const displayH = h % 12 === 0 ? 12 : h % 12;
  const displayM = m < 10 ? `0${m}` : `${m}`;
  return `${displayH}:${displayM} ${ampm}`;
}

function formatDuration(minutes) {
  if (!minutes) return '';
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  if (h === 0) return `${m} min`;
  if (m === 0) return `${h} hr`;
  return `${h} hr ${m} min`;
}

export function formatCurrencyPrice(amount, currencyCode = 'MYR') {
  if (!amount && amount !== 0) return '';
  const num = typeof amount === 'number' ? amount : parseInt(String(amount).replace(/[^0-9]/g, ''), 10);
  if (isNaN(num)) return String(amount);
  const formatted = num.toLocaleString('en-US');
  const code = (currencyCode || 'MYR').toUpperCase();
  switch (code) {
    case 'MYR': return `RM ${formatted}`;
    case 'USD': return `$${formatted}`;
    case 'SGD': return `S$${formatted}`;
    case 'EUR': return `€${formatted}`;
    case 'GBP': return `£${formatted}`;
    case 'JPY': return `¥${formatted}`;
    case 'AUD': return `A$${formatted}`;
    case 'CAD': return `C$${formatted}`;
    case 'CNY': return `¥${formatted}`;
    case 'THB': return `฿${formatted}`;
    case 'IDR': return `Rp ${formatted}`;
    case 'TWD': return `NT$${formatted}`;
    case 'KRW': return `₩${formatted}`;
    case 'HKD': return `HK$${formatted}`;
    default: return `${code} ${formatted}`;
  }
}

function parseStructuredBlock(block, curr, fallbackUrl) {
  if (!block || !Array.isArray(block)) return [];
  const flightSections = [];
  if (block[2] && Array.isArray(block[2][0])) flightSections.push(...block[2][0]);
  if (block[3] && Array.isArray(block[3][0])) flightSections.push(...block[3][0]);

  const results = [];
  const seen = new Set();

  for (const it of flightSections) {
    if (!Array.isArray(it) || it.length < 2) continue;
    const flightData = it[0];
    const priceInfo = it[1];
    if (!Array.isArray(flightData) || flightData.length < 3) continue;

    const airlineCode = flightData[0] || '';
    const airlineName = Array.isArray(flightData[1]) ? flightData[1][0] : (flightData[1] || 'Unknown Airline');
    const rawSegments = Array.isArray(flightData[2]) ? flightData[2] : [];
    const priceNumeric = (priceInfo && Array.isArray(priceInfo[0])) ? priceInfo[0][1] : 0;
    if (!priceNumeric && rawSegments.length === 0) continue;

    const depAirportCode = flightData[3] || (rawSegments[0] ? rawSegments[0][3] : '');
    const arrAirportCode = flightData[6] || (rawSegments.length > 0 ? rawSegments[rawSegments.length - 1][6] : '');
    const totalDurationMin = flightData[9] || 0;
    const stopsCount = flightData[10] || 0;

    // Layovers
    const layovers = [];
    if (Array.isArray(flightData[13])) {
      for (const lay of flightData[13]) {
        if (Array.isArray(lay)) {
          const durMin = lay[0] || 0;
          const airportCode = lay[1] || lay[2] || '';
          const airportName = lay[4] || '';
          const city = lay[5] || '';
          layovers.push({
            duration: formatDuration(durMin),
            durationMinutes: durMin,
            airportCode,
            airportName,
            city,
            text: `${formatDuration(durMin)} layover · ${city || airportName} (${airportCode})`,
          });
        }
      }
    }

    // Segments with legroom, aircraft, flight numbers, emissions
    const segments = [];
    for (const seg of rawSegments) {
      if (!Array.isArray(seg)) continue;
      const segDepCode = seg[3] || '';
      const segDepName = seg[4] || '';
      const segArrName = seg[5] || '';
      const segArrCode = seg[6] || '';
      const segDepTime = formatTime(seg[8]);
      const segArrTime = formatTime(seg[10]);
      const segDuration = formatDuration(seg[11]);
      const legroom = seg[14] || seg[30] || '';
      const aircraft = seg[17] || '';
      
      let flightNumber = '';
      let segAirline = airlineName;
      if (Array.isArray(seg[22])) {
        const alCode = seg[22][0] || '';
        const fNum = seg[22][1] || '';
        flightNumber = alCode && fNum ? `${alCode} ${fNum}` : fNum;
        if (seg[22][3]) segAirline = seg[22][3];
      }

      // Estimate CO2
      const co2Kg = seg[31] ? Math.round(seg[31] / 1000) : 0;

      segments.push({
        departureAirport: segDepName,
        departureCode: segDepCode,
        departureTime: segDepTime,
        arrivalAirport: segArrName,
        arrivalCode: segArrCode,
        arrivalTime: segArrTime,
        duration: segDuration,
        legroom: legroom ? `${legroom} legroom` : '',
        aircraft,
        flightNumber,
        airline: segAirline,
        delayInfo: '',
        emissions: co2Kg ? `${co2Kg} kg CO2e` : '',
      });
    }

    const stops = stopsCount === 0 ? 'Nonstop' : `${stopsCount} stop${stopsCount > 1 ? 's' : ''}`;
    const key = `${airlineName}-${totalDurationMin}-${priceNumeric}-${depAirportCode}-${arrAirportCode}`;
    if (seen.has(key)) continue;
    seen.add(key);

    results.push({
      airline: airlineName,
      airlineCode,
      logoUrl: airlineCode ? `https://www.gstatic.com/flights/airline_logos/70px/${airlineCode}.png` : null,
      price: formatCurrencyPrice(priceNumeric, curr),
      priceNumeric,
      duration: formatDuration(totalDurationMin),
      stops,
      departure: {
        airport: rawSegments[0] ? rawSegments[0][4] : depAirportCode,
        time: rawSegments[0] ? formatTime(rawSegments[0][8]) : '',
        date: '',
      },
      arrival: {
        airport: rawSegments.length > 0 ? rawSegments[rawSegments.length - 1][5] : arrAirportCode,
        time: rawSegments.length > 0 ? formatTime(rawSegments[rawSegments.length - 1][10]) : '',
        date: '',
      },
      deepLink: fallbackUrl,
      layovers,
      segments,
    });
  }

  return results;
}

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();

  const params = req.method === 'POST' ? (req.body || {}) : req.query;
  const rawOrigin = (params.origin || '').trim();
  const rawDestination = (params.destination || '').trim();
  const departureDate = (params.departureDate || '').trim();
  const returnDate = (params.returnDate || '').trim();
  const tripType = (params.tripType || 'oneway').toLowerCase();
  const adults = Math.max(1, parseInt(params.adults, 10) || 1);
  const children = Math.max(0, parseInt(params.children, 10) || 0);
  const cabinClass = (params.cabinClass || 'economy').toLowerCase();
  const currency = (params.currency || 'MYR').toUpperCase();

  const origin = normalizeLocation(rawOrigin) || rawOrigin;
  const destination = normalizeLocation(rawDestination) || rawDestination;

  let fallbackQuery = `Flights to ${destination || 'anywhere'} from ${origin || 'here'}`;
  if (departureDate) fallbackQuery += ` on ${departureDate}`;
  if (tripType === 'roundtrip' && returnDate) fallbackQuery += ` through ${returnDate}`;
  const fallbackUrl = `https://www.google.com/travel/flights?q=${encodeURIComponent(fallbackQuery)}&curr=${currency}&hl=en`;

  if (tripType === 'multicity') {
    return res.status(200).json({
      success: true,
      isMultiCity: true,
      message: 'Multi-city routes are best explored directly on Google Flights.',
      flights: [],
      fallbackUrl,
    });
  }

  if (!origin || !destination || !departureDate) {
    return res.status(400).json({
      success: false,
      error: 'Missing required parameters: origin, destination, and departureDate are required.',
      fallbackUrl,
    });
  }

  let query = `Flights to ${destination} from ${origin} on ${departureDate}`;
  if (tripType === 'roundtrip' && returnDate) {
    query += ` through ${returnDate}`;
  } else {
    query += ' one way';
  }

  if (cabinClass === 'business') query += ' business class';
  else if (cabinClass === 'first') query += ' first class';
  else if (cabinClass === 'premiumeconomy') query += ' premium economy';

  if (adults > 1) query += ` ${adults} adults`;
  if (children > 0) query += ` ${children} children`;

  const searchUrl = `https://www.google.com/travel/flights?q=${encodeURIComponent(query)}&curr=${currency}&hl=en`;

  try {
    const response = await fetch(searchUrl, {
      signal: AbortSignal.timeout(15000),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9',
        'Cache-Control': 'no-cache',
      },
    });

    if (!response.ok) {
      return res.status(200).json({
        success: false,
        error: `Upstream response status: ${response.status}`,
        flights: [],
        fallbackUrl: searchUrl,
      });
    }

    const html = await response.text();

    // 1. Primary Strategy: Extract structured JSON data blocks
    let structuredFlights = [];
    const callbackRegex = /AF_initDataCallback\(({[\s\S]*?})\);/g;
    let match;
    while ((match = callbackRegex.exec(html)) !== null) {
      const callbackStr = match[1];
      if (callbackStr.includes('sideChannel:') && callbackStr.includes('data:')) {
        const dataMatch = callbackStr.match(/data:\s*(\[[\s\S]*?\])\s*,\s*sideChannel:/);
        if (dataMatch) {
          try {
            const block = JSON.parse(dataMatch[1]);
            const extracted = parseStructuredBlock(block, currency, searchUrl);
            if (extracted.length > structuredFlights.length) {
              structuredFlights = extracted;
            }
          } catch (e) {
            // continue
          }
        }
      }
    }

    if (structuredFlights.length > 0) {
      return res.status(200).json({
        success: true,
        count: structuredFlights.length,
        flights: structuredFlights.slice(0, 20),
        fallbackUrl: searchUrl,
      });
    }

    // 2. Fallback Strategy: Accessibility aria-label regex parser
    const cardRegex = /<li[^>]*class="[^"]*pIav2d[^"]*"[^>]*>(.*?)<\/li>/gs;
    const cards = [...html.matchAll(cardRegex)];
    const flights = [];
    const seen = new Set();

    for (const card of cards) {
      const cardHtml = card[1];
      const ariaMatch = cardHtml.match(/role="link"\s+aria-label="([^"]*Select flight[^"]*)"/);
      if (!ariaMatch) continue;

      const text = ariaMatch[1].replace(/\s+/g, ' ');
      const priceMatch = text.match(/From\s+([0-9,]+)\s+([a-zA-Z\s]+?)\s+(?:round trip|one way|total)/i)
                      || text.match(/([0-9,]+)\s+([a-zA-Z\s]+?)\.\s+/);
      const airlineMatch = text.match(/with\s+([^.]+)\./);
      const timesMatch = text.match(/Leaves\s+(.+?)\s+at\s+([0-9:APMapm\u202F\s]+)\s+on\s+(.+?)\s+and arrives at\s+(.+?)\s+at\s+([0-9:APMapm\u202F\s]+)\s+on\s+(.+?)\./);
      const durationMatch = text.match(/Total duration\s+([^.]+)\./);
      const stopsMatch = text.match(/((?:Nonstop|\d+\s+stop[s]?)(?:\s+flight)?)/i);
      const layoverMatch = text.match(/Layover\s*\([0-9]+\s+of\s+[0-9]+\)\s+is\s+a\s+([^.]+)\./);

      const logoMatch = cardHtml.match(/https:\/\/www\.gstatic\.com\/flights\/airline_logos\/[^\s"')]+/);
      const airline = airlineMatch ? airlineMatch[1].trim() : 'Unknown Airline';
      const duration = durationMatch ? durationMatch[1].trim() : '';
      const stops = stopsMatch ? stopsMatch[1].replace(/flight/i, '').trim() : 'Nonstop';
      const priceNumeric = priceMatch ? parseInt(priceMatch[1].replace(/,/g, ''), 10) : 0;
      const formattedPrice = formatCurrencyPrice(priceNumeric, currency);

      const key = `${airline}-${duration}-${timesMatch ? timesMatch[2] : ''}-${priceNumeric}`;
      if (seen.has(key)) continue;
      seen.add(key);

      const layovers = layoverMatch ? [{ text: layoverMatch[1].trim(), duration: '', airportName: '' }] : [];

      flights.push({
        airline,
        logoUrl: logoMatch ? logoMatch[0] : null,
        stops,
        duration,
        price: formattedPrice || `${currency} ${priceNumeric || 'Check price'}`,
        priceNumeric,
        departure: {
          airport: timesMatch ? timesMatch[1].trim() : origin,
          time: timesMatch ? timesMatch[2].trim() : '',
          date: timesMatch ? timesMatch[3].trim() : departureDate,
        },
        arrival: {
          airport: timesMatch ? timesMatch[4].trim() : destination,
          time: timesMatch ? timesMatch[5].trim() : '',
          date: timesMatch ? timesMatch[6].trim() : (returnDate || departureDate),
        },
        deepLink: searchUrl,
        layovers,
        segments: [],
      });

      if (flights.length >= 15) break;
    }

    return res.status(200).json({
      success: true,
      count: flights.length,
      flights,
      fallbackUrl: searchUrl,
    });
  } catch (error) {
    console.error('Flight check error:', error);
    return res.status(200).json({
      success: false,
      error: error.message || 'Error querying flights',
      flights: [],
      fallbackUrl: searchUrl,
    });
  }
}

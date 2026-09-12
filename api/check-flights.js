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

export function formatLegroom(val) {
  if (!val && val !== 0) return '';
  if (Array.isArray(val)) val = val.filter(x => x !== null && x !== undefined).join(' ');
  let str = String(val).trim();
  if (!str) return '';

  if (/in(ch(es)?)?/i.test(str)) {
    const numMatch = str.match(/(\d+(?:\.\d+)?(?:\s*[-–]\s*\d+(?:\.\d+)?)?)\s*in/i);
    if (numMatch) return `${numMatch[1]} in legroom`;
    return str.replace(/inches/i, 'in');
  }

  if (/cm/i.test(str)) {
    return str.includes('legroom') ? str : `${str} legroom`;
  }

  const numbers = str.match(/\d+(?:\.\d+)?/g);
  if (numbers && numbers.length > 0) {
    if (numbers.length === 1) {
      const n = parseFloat(numbers[0]);
      return n > 50 ? `${n} cm legroom` : `${n} in legroom`;
    } else if (numbers.length >= 2) {
      const n1 = parseFloat(numbers[0]);
      const n2 = parseFloat(numbers[1]);
      if (n1 >= 25 && n2 >= 25) return `${n1}–${n2} in legroom`;
      if (n1 < 25 && n2 >= 25) return `${n2} in legroom (${n1} in width)`;
      return `${n1}–${n2} in legroom`;
    }
  }

  return str.includes('legroom') ? str : `${str} legroom`;
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
    const rawStops = typeof flightData[10] === 'number' ? flightData[10] : 0;

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

      // In-flight amenities flags
      const amenities = [];
      const flags = Array.isArray(seg[12]) ? seg[12] : [];
      if (flags[1] === 1) amenities.push('Free Wi-Fi');
      if (flags[9] === 1) amenities.push('In-seat power & USB outlets');
      if (flags[11] === 2 || flags[11] === 3) amenities.push('On-demand video');
      if (flags[5] === 1) amenities.push('Extra reclining seat');

      // Contrail warming potential
      let contrail = '';
      if (seg[32] === 1) contrail = 'Contrail: Low';
      else if (seg[32] === 2) contrail = 'Contrail: Medium';
      else if (seg[32] === 3) contrail = 'Contrail: High';

      segments.push({
        departureAirport: segDepName,
        departureCode: segDepCode,
        departureTime: segDepTime,
        arrivalAirport: segArrName,
        arrivalCode: segArrCode,
        arrivalTime: segArrTime,
        duration: segDuration,
        legroom: formatLegroom(seg[14] || seg[30] || ''),
        aircraft,
        flightNumber,
        airline: segAirline,
        delayInfo: '',
        emissions: co2Kg ? `${co2Kg} kg CO2e` : '',
        amenities,
        contrail,
      });
    }

    const stopsCount = Math.max(rawStops, layovers.length, Math.max(0, rawSegments.length - 1));
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

async function scrapeGoogleFlights(query, currency, fallbackUrl, origin, destination, depDate, arrDate) {
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

    if (!response.ok) return [];

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
            const extracted = parseStructuredBlock(block, currency, fallbackUrl);
            if (extracted.length > structuredFlights.length) {
              structuredFlights = extracted;
            }
          } catch (e) {}
        }
      }
    }

    if (structuredFlights.length > 0) {
      return structuredFlights.slice(0, 20);
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
          date: timesMatch ? timesMatch[3].trim() : depDate,
        },
        arrival: {
          airport: timesMatch ? timesMatch[4].trim() : destination,
          time: timesMatch ? timesMatch[5].trim() : '',
          date: timesMatch ? timesMatch[6].trim() : arrDate,
        },
        deepLink: fallbackUrl,
        layovers,
        segments: [],
      });

      if (flights.length >= 15) break;
    }

    return flights;
  } catch (err) {
    return [];
  }
}

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();

  let searchUrl = 'https://www.google.com/travel/flights?hl=en';
  let fallbackUrl = searchUrl;

  try {
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

    let fallbackQuery = `Flights from ${origin || 'here'} to ${destination || 'anywhere'}`;
    if (departureDate) fallbackQuery += ` on ${departureDate}`;
    if (tripType === 'roundtrip' && returnDate) fallbackQuery += ` through ${returnDate}`;
    fallbackUrl = `https://www.google.com/travel/flights?q=${encodeURIComponent(fallbackQuery)}&curr=${currency}&hl=en`;
    searchUrl = fallbackUrl;

    if (tripType === 'multicity') {
      return res.status(200).json({
        success: true,
        isMultiCity: true,
        message: 'Multi-city routes are best explored directly on Google Flights.',
        flights: [],
        outboundFlights: [],
        returnFlights: [],
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

    function buildLegQuery(from, to, date) {
      let q = `Flights from ${from} to ${to} on ${date} one way`;
      if (cabinClass === 'business') q += ' business class';
      else if (cabinClass === 'first') q += ' first class';
      else if (cabinClass === 'premiumeconomy') q += ' premium economy';
      if (adults > 1) q += ` ${adults} adults`;
      if (children > 0) q += ` ${children} children`;
      return q;
    }

    if (tripType === 'roundtrip' && returnDate) {
      const outQuery = buildLegQuery(origin, destination, departureDate);
      const retQuery = buildLegQuery(destination, origin, returnDate);

      const [outbound, returning] = await Promise.all([
        scrapeGoogleFlights(outQuery, currency, fallbackUrl, origin, destination, departureDate, returnDate),
        scrapeGoogleFlights(retQuery, currency, fallbackUrl, destination, origin, returnDate, returnDate),
      ]);

      return res.status(200).json({
        success: true,
        tripType: 'roundtrip',
        count: outbound.length + returning.length,
        outboundFlights: outbound,
        returnFlights: returning,
        flights: outbound,
        fallbackUrl,
      });
    }

    // One way search
    const query = buildLegQuery(origin, destination, departureDate);
    const flights = await scrapeGoogleFlights(query, currency, fallbackUrl, origin, destination, departureDate, departureDate);

    return res.status(200).json({
      success: true,
      tripType: 'oneway',
      count: flights.length,
      outboundFlights: flights,
      returnFlights: [],
      flights,
      fallbackUrl,
    });
  } catch (error) {
    console.error('Flight check error:', error);
    return res.status(200).json({
      success: false,
      error: error.message || 'Error querying flights',
      flights: [],
      outboundFlights: [],
      returnFlights: [],
      fallbackUrl: searchUrl,
    });
  }
}

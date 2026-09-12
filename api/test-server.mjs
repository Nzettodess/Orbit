// Automated Test Suite for Orbit Flight API (Local & Production)
// Usage: node api/test-server.mjs [optional-base-url]
// Example: node api/test-server.mjs http://localhost:3001

import http from 'http';
import handler from './check-flights.js';

const targetUrl = process.argv[2] || 'http://localhost:3001';
const futureDate = new Date(Date.now() + 14 * 86400000).toISOString().split('T')[0];

console.log('='.repeat(60));
console.log(`✈️  ORBIT FLIGHT API AUTOMATED TEST SUITE`);
console.log(`Target: ${targetUrl}`);
console.log(`Date:   ${futureDate}`);
console.log('='.repeat(60) + '\n');

let passedCount = 0;
let failedCount = 0;

async function checkServerAlive() {
  try {
    const res = await fetch(`${targetUrl}/api/health`, { signal: AbortSignal.timeout(3000) });
    if (res.ok) {
      const data = await res.json();
      return { alive: true, data };
    }
  } catch {
    // server unreachable on targetUrl
  }
  return { alive: false };
}

async function sendRequest(path, options = {}) {
  const url = `${targetUrl}${path}`;
  const start = Date.now();
  try {
    const res = await fetch(url, {
      ...options,
      signal: AbortSignal.timeout(20000),
      headers: {
        'Content-Type': 'application/json',
        ...(options.headers || {}),
      },
    });
    const elapsed = Date.now() - start;
    const body = await res.json().catch(() => null);
    return { status: res.status, ok: res.ok, body, elapsed };
  } catch (err) {
    const elapsed = Date.now() - start;
    return { status: 0, ok: false, error: err.message, elapsed };
  }
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

async function runTest(name, fn) {
  process.stdout.write(`  • ${name.padEnd(42)} `);
  const start = Date.now();
  try {
    await fn();
    const duration = Date.now() - start;
    console.log(`\x1b[32m[PASS]\x1b[0m (${duration}ms)`);
    passedCount++;
  } catch (err) {
    const duration = Date.now() - start;
    console.log(`\x1b[31m[FAIL]\x1b[0m (${duration}ms)`);
    console.log(`    \x1b[33mError: ${err.message}\x1b[0m`);
    failedCount++;
  }
}

async function main() {
  const health = await checkServerAlive();
  
  if (!health.alive) {
    console.log(`\x1b[33m⚠️ Local server is not currently running on ${targetUrl}.\x1b[0m`);
    console.log(`Starting temporary in-memory test runner on port 3099 to validate code integrity...\n`);

    const tempPort = 3099;
    const tempServer = http.createServer(async (req, res) => {
      const customRes = {
        setHeader: () => {},
        status: (code) => ({
          json: (data) => {
            res.writeHead(code, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify(data));
          },
          end: () => res.end(),
        }),
      };

      if (req.url === '/api/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'healthy' }));
        return;
      }

      let body = '';
      req.on('data', chunk => { body += chunk; });
      req.on('end', async () => {
        req.body = body ? JSON.parse(body) : {};
        const url = new URL(req.url, `http://localhost:${tempPort}`);
        req.query = Object.fromEntries(url.searchParams);
        await handler(req, customRes);
      });
    });

    await new Promise(resolve => tempServer.listen(tempPort, resolve));
    
    // Redirect tests to tempPort
    const prevTarget = targetUrl;
    return runAllTests(`http://localhost:${tempPort}`).finally(() => {
      tempServer.close();
    });
  }

  console.log(`\x1b[32m✔ Server is ONLINE\x1b[0m (Uptime: ${health.data?.uptimeSeconds ?? 0}s)\n`);
  await runAllTests(targetUrl);
}

async function runAllTests(baseUrl) {
  console.log(`Running test suite against ${baseUrl}...`);

  // Test 1: Health endpoint
  await runTest('1. Health Check Endpoint', async () => {
    const res = await fetch(`${baseUrl}/api/health`);
    assert(res.status === 200, `Expected 200, got ${res.status}`);
    const data = await res.json();
    assert(data.status === 'healthy', `Expected status 'healthy', got ${data.status}`);
  });

  // Test 2: Validation on missing params
  await runTest('2. Validation on Missing Params', async () => {
    const res = await fetch(`${baseUrl}/api/check-flights`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ origin: '', destination: '' }),
    });
    assert(res.status === 400, `Expected status 400, got ${res.status}`);
    const data = await res.json();
    assert(data.success === false, 'Expected success: false');
    assert(typeof data.error === 'string', 'Expected error message');
    assert(data.fallbackUrl.includes('google.com/travel/flights'), 'Expected valid fallbackUrl');
  });

  // Test 3: Multi-city redirection
  await runTest('3. Multi-city Fallback Handling', async () => {
    const res = await fetch(`${baseUrl}/api/check-flights`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        tripType: 'multicity',
        origin: 'KUL',
        destination: 'NRT',
        departureDate: futureDate,
      }),
    });
    assert(res.status === 200, `Expected status 200, got ${res.status}`);
    const data = await res.json();
    assert(data.success === true, 'Expected success: true');
    assert(data.isMultiCity === true, 'Expected isMultiCity: true');
    assert(data.fallbackUrl.includes('google.com/travel/flights'), 'Expected Google Flights fallback');
  });

  // Test 4: One-Way Domestic Route (PEN -> SZB)
  await runTest('4. Domestic Route Query (PEN -> SZB)', async () => {
    const res = await fetch(`${baseUrl}/api/check-flights`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        origin: 'PEN',
        destination: 'SZB',
        departureDate: futureDate,
        currency: 'MYR',
      }),
    });
    assert(res.status === 200, `Expected status 200, got ${res.status}`);
    const data = await res.json();
    assert(data.fallbackUrl.includes('SZB'), 'Expected fallbackUrl to contain SZB');
    assert(Array.isArray(data.flights), 'Expected flights array');
    console.log(`\n      [Info] Returned ${data.flights.length} flights; fallbackUrl ready.`);
  });

  // Test 5: International Route & Currency (KUL -> SIN in USD)
  await runTest('5. International Route (KUL -> SIN, USD)', async () => {
    const res = await fetch(`${baseUrl}/api/check-flights`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        origin: 'KUL',
        destination: 'SIN',
        departureDate: futureDate,
        currency: 'USD',
      }),
    });
    assert(res.status === 200, `Expected status 200, got ${res.status}`);
    const data = await res.json();
    assert(data.fallbackUrl.includes('curr=USD'), 'Expected currency parameter in fallbackUrl');
    assert(Array.isArray(data.flights), 'Expected flights array');
  });

  // Test 6: Round-Trip Route
  await runTest('6. Round-Trip Route (KUL -> BKK)', async () => {
    const returnDate = new Date(Date.now() + 21 * 86400000).toISOString().split('T')[0];
    const res = await fetch(`${baseUrl}/api/check-flights`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        origin: 'KUL',
        destination: 'BKK',
        departureDate: futureDate,
        returnDate,
        tripType: 'roundtrip',
        currency: 'MYR',
      }),
    });
    assert(res.status === 200, `Expected status 200, got ${res.status}`);
    const data = await res.json();
    assert(data.fallbackUrl.includes('through'), 'Expected roundtrip query format');
  });

  console.log('\n' + '='.repeat(60));
  if (failedCount === 0) {
    console.log(`\x1b[32m✔ ALL ${passedCount} TESTS PASSED SUCCESSFULLY!\x1b[0m`);
  } else {
    console.log(`\x1b[31m✖ TEST SUITE FINISHED: ${passedCount} passed, ${failedCount} failed.\x1b[0m`);
  }
  console.log('='.repeat(60) + '\n');
}

main().catch(err => {
  console.error('Fatal test runner error:', err);
  process.exit(1);
});

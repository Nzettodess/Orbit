import http from 'http';
import handler from './check-flights.js';

const PORT = 3001;

// Global process crash guards to prevent server from dying unexpectedly
process.on('uncaughtException', (err) => {
  console.error('[Local Server Crash Guard] Uncaught Exception:', err?.stack || err);
});

process.on('unhandledRejection', (reason) => {
  console.error('[Local Server Crash Guard] Unhandled Rejection:', reason);
});

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept, X-Requested-With',
  'Access-Control-Max-Age': '86400',
};

function createMockResponse(res, cors, timeStr) {
  return {
    setHeader: (k, v) => res.setHeader(k, v),
    status: (code) => ({
      json: (data) => {
        if (!res.headersSent) {
          res.writeHead(code, {
            'Content-Type': 'application/json',
            ...cors,
          });
          res.end(JSON.stringify(data));
        }
        console.log(`[Local Server ${timeStr}] Responded ${code}: success=${data?.success}, flights=${data?.flights?.length ?? 0}`);
      },
      end: () => {
        if (!res.headersSent) {
          res.writeHead(code, cors);
          res.end();
        }
      },
    }),
  };
}

const server = http.createServer(async (req, res) => {
  const timeStr = new Date().toLocaleTimeString();

  // Guard against slow hanging connections (25s timeout)
  req.setTimeout(25000, () => {
    console.warn(`[Local Server ${timeStr}] Request timed out for ${req.url}`);
    if (!res.headersSent) {
      res.writeHead(504, { 'Content-Type': 'application/json', ...corsHeaders });
      res.end(JSON.stringify({ success: false, error: 'Request timeout (25s)', flights: [] }));
    }
  });

  // Set default CORS headers
  for (const [key, value] of Object.entries(corsHeaders)) {
    res.setHeader(key, value);
  }

  // Preflight OPTIONS handling
  if (req.method === 'OPTIONS') {
    res.writeHead(204, corsHeaders);
    res.end();
    return;
  }

  const url = new URL(req.url, `http://${req.headers.host || 'localhost:3001'}`);

  // Health check endpoint for automated tests & monitoring
  if (url.pathname === '/api/health' || url.pathname === '/health' || url.pathname === '/') {
    res.writeHead(200, { 'Content-Type': 'application/json', ...corsHeaders });
    res.end(JSON.stringify({
      status: 'healthy',
      service: 'orbit-flight-checker-local',
      uptimeSeconds: Math.round(process.uptime()),
      timestamp: new Date().toISOString(),
    }));
    return;
  }

  if (url.pathname === '/api/check-flights') {
    if (req.method === 'POST') {
      let body = '';
      req.on('data', (chunk) => { body += chunk; });
      req.on('end', async () => {
        try {
          req.body = body ? JSON.parse(body) : {};
        } catch {
          req.body = {};
        }
        req.query = Object.fromEntries(url.searchParams);
        console.log(`[Local Server ${timeStr}] POST: ${req.body.origin || 'unknown'} -> ${req.body.destination || 'unknown'} (${req.body.departureDate || 'no date'}, ${req.body.currency || 'MYR'})`);

        const customRes = createMockResponse(res, corsHeaders, timeStr);
        try {
          await handler(req, customRes);
        } catch (err) {
          console.error(`[Local Server ${timeStr}] Handler error:`, err);
          if (!res.headersSent) {
            res.writeHead(500, { 'Content-Type': 'application/json', ...corsHeaders });
            res.end(JSON.stringify({ success: false, error: err.message, flights: [] }));
          }
        }
      });
    } else {
      req.query = Object.fromEntries(url.searchParams);
      console.log(`[Local Server ${timeStr}] GET:`, req.query);
      const customRes = createMockResponse(res, corsHeaders, timeStr);
      try {
        await handler(req, customRes);
      } catch (err) {
        console.error(`[Local Server ${timeStr}] Handler error:`, err);
        if (!res.headersSent) {
          res.writeHead(500, { 'Content-Type': 'application/json', ...corsHeaders });
          res.end(JSON.stringify({ success: false, error: err.message, flights: [] }));
        }
      }
    }
  } else {
    res.writeHead(404, corsHeaders);
    res.end(JSON.stringify({ error: 'Not Found', path: url.pathname }));
  }
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`\n[Local Server Error] Port ${PORT} is already in use by another process!`);
    console.error(`Run: Get-Process node | Stop-Process -Force (PowerShell) or kill the task.\n`);
  } else {
    console.error('[Local Server Error]', err);
  }
});

server.listen(PORT, () => {
  console.log(`[Local API Server] Running on http://localhost:${PORT}`);
  console.log(`  - Health:  http://localhost:${PORT}/api/health`);
  console.log(`  - Flights: http://localhost:${PORT}/api/check-flights`);
});

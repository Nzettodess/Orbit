import http from 'http';
import handler from './check-flights.js';

const PORT = 3001;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept, X-Requested-With',
  'Access-Control-Max-Age': '86400',
};

const server = http.createServer(async (req, res) => {
  const timeStr = new Date().toLocaleTimeString();
  
  // Set default CORS headers on the response object
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
  
  if (url.pathname === '/api/check-flights') {
    if (req.method === 'POST') {
      let body = '';
      req.on('data', chunk => { body += chunk; });
      req.on('end', async () => {
        try {
          req.body = body ? JSON.parse(body) : {};
        } catch {
          req.body = {};
        }
        req.query = Object.fromEntries(url.searchParams);
        console.log(`[Local Server ${timeStr}] POST /api/check-flights: ${req.body.origin} -> ${req.body.destination} (${req.body.departureDate}, ${req.body.currency || 'MYR'})`);
        
        const customRes = {
          setHeader: (k, v) => res.setHeader(k, v),
          status: (code) => ({
            json: (data) => {
              res.writeHead(code, {
                'Content-Type': 'application/json',
                ...corsHeaders,
              });
              res.end(JSON.stringify(data));
              console.log(`[Local Server ${timeStr}] Responded ${code}: success=${data.success}, flights=${data.flights?.length ?? 0}`);
            },
            end: () => {
              res.writeHead(code, corsHeaders);
              res.end();
            },
          }),
        };

        try {
          await handler(req, customRes);
        } catch (err) {
          console.error(`[Local Server ${timeStr}] Handler error:`, err);
          res.writeHead(500, {
            'Content-Type': 'application/json',
            ...corsHeaders,
          });
          res.end(JSON.stringify({ success: false, error: err.message, flights: [] }));
        }
      });
    } else {
      req.query = Object.fromEntries(url.searchParams);
      console.log(`[Local Server ${timeStr}] GET /api/check-flights:`, req.query);
      const customRes = {
        setHeader: (k, v) => res.setHeader(k, v),
        status: (code) => ({
          json: (data) => {
            res.writeHead(code, {
              'Content-Type': 'application/json',
              ...corsHeaders,
            });
            res.end(JSON.stringify(data));
            console.log(`[Local Server ${timeStr}] Responded ${code}: success=${data.success}, flights=${data.flights?.length ?? 0}`);
          },
          end: () => {
            res.writeHead(code, corsHeaders);
            res.end();
          },
        }),
      };
      try {
        await handler(req, customRes);
      } catch (err) {
        console.error(`[Local Server ${timeStr}] Handler error:`, err);
        res.writeHead(500, {
          'Content-Type': 'application/json',
          ...corsHeaders,
        });
        res.end(JSON.stringify({ success: false, error: err.message, flights: [] }));
      }
    }
  } else {
    res.writeHead(404, corsHeaders);
    res.end('Not Found');
  }
});

server.listen(PORT, () => {
  console.log(`[Local API Server] Running on http://localhost:${PORT}/api/check-flights`);
});

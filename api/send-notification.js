// Vercel serverless function to send OneSignal push notifications
// Environment variables ONESIGNAL_API_KEY and ONESIGNAL_APP_ID must be set in Vercel dashboard

export default async function handler(req, res) {
    // Set CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    // Handle preflight
    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    // Only allow POST requests
    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
    }

    const { playerIds, title, message, data } = req.body;

    // Validate required fields
    if (!playerIds || !Array.isArray(playerIds) || playerIds.length === 0) {
        return res.status(400).json({ error: 'playerIds array is required' });
    }

    if (!message) {
        return res.status(400).json({ error: 'message is required' });
    }

    // Get secrets from environment
    const apiKey = process.env.ONESIGNAL_API_KEY;
    const appId = process.env.ONESIGNAL_APP_ID;

    if (!apiKey || !appId) {
        console.error('Missing ONESIGNAL_API_KEY or ONESIGNAL_APP_ID environment variables');
        return res.status(500).json({ error: 'Server configuration error' });
    }

    // Build OneSignal notification payload
    const notificationPayload = {
        app_id: appId,
        include_player_ids: playerIds,
        headings: { en: title || 'Orbit' },
        contents: { en: message },
        data: data || {},
        web_url: '/', // Open app when notification is clicked
    };

    try {
        // Call OneSignal REST API
        const response = await fetch('https://onesignal.com/api/v1/notifications', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Basic ${apiKey}`,
            },
            body: JSON.stringify(notificationPayload),
        });

        const result = await response.json();

        if (!response.ok) {
            console.error('OneSignal API error:', result);
            return res.status(response.status).json({ error: 'OneSignal API error', details: result });
        }

        console.log('Notification sent successfully:', result.id);
        return res.status(200).json({ success: true, notificationId: result.id });
    } catch (error) {
        console.error('Error sending notification:', error);
        return res.status(500).json({ error: 'Failed to send notification' });
    }
}

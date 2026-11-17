export async function onRequestGet() {
  try {
    const response = await fetch('https://whitebit.com/api/v4/public/ticker', {
      signal: AbortSignal.timeout(5000),
    });
    if (!response.ok) throw new Error('WhiteBIT ticker unavailable');

    const ticker = await response.json();
    const price = Number(ticker.WBT_USDT?.last_price);
    if (!Number.isFinite(price) || price <= 0) {
      throw new Error('Invalid WBT/USDT price');
    }

    return Response.json({ price }, {
      headers: { 'Cache-Control': 'public, max-age=30, s-maxage=30' },
    });
  } catch {
    return Response.json({ error: 'WBT/USDT unavailable' }, { status: 502 });
  }
}

export async function onRequestGet({ request }) {
  const soulId = new URL(request.url).searchParams.get('soulId');
  if (!soulId || !/^[1-9][0-9]{0,77}$/.test(soulId) ||
      BigInt(soulId) >= (1n << 256n)) {
    return Response.json({ error: 'Invalid Soul ID' }, { status: 400 });
  }

  try {
    const response = await fetch(
      `https://explorer.whitechain.io/soul/${soulId}?tab=events`,
      { signal: AbortSignal.timeout(7000) },
    );
    if (!response.ok) throw new Error('Whitechain Explorer unavailable');

    // Use Explorer's aggregate, since individual event amounts are rounded.
    const html = await response.text();
    const match = html.match(
      /aria-label="Sum of all SoulDrop rewards claimed by this Soul\."[^>]*>[^]*?<\/span><\/span><\/div>\s*<div[^>]*>\s*([0-9][0-9,]*(?:\.[0-9]+)?)\s+WBT\s*<\/div>/,
    );
    const claimed = Number(match?.[1].replaceAll(',', ''));
    if (!Number.isFinite(claimed)) throw new Error('Claimed total unavailable');

    return Response.json({ claimed }, {
      headers: { 'Cache-Control': 'public, max-age=60' },
    });
  } catch {
    return Response.json({ error: 'Claimed total unavailable' }, { status: 502 });
  }
}

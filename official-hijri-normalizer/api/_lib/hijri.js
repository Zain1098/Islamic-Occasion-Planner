const SOURCES = {
  mora: {
    discoveryUrl: process.env.MORA_NEWS_URL || 'https://www.mora.gov.pk/LatestNews',
    allowedHosts: ['mora.gov.pk', 'www.mora.gov.pk'],
  },
  radio_pakistan: {
    discoveryUrl: process.env.RADIO_PAKISTAN_NEWS_URL || 'https://www.radio.gov.pk/',
    allowedHosts: ['radio.gov.pk', 'www.radio.gov.pk', 'new.radio.gov.pk'],
  },
};

const MONTHS = {
  muharram: 1,
  safar: 2,
  'rabi-ul-awwal': 3,
  'rabi ul awwal': 3,
  'rabi al-awwal': 3,
  'rabi-us-sani': 4,
  'rabi ul sani': 4,
  'jumada al-awwal': 5,
  'jumada ul awwal': 5,
  'jumada al-sani': 6,
  'jumada ul sani': 6,
  rajab: 7,
  shaban: 8,
  'sha ban': 8,
  ramadan: 9,
  shawwal: 10,
  'zul qaadah': 11,
  'dhu al qidah': 11,
  'zul hijjah': 12,
  'dhu al hijjah': 12,
};

function plainText(html) {
  return html.replace(/<script[\s\S]*?<\/script>/gi, ' ').replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<[^>]+>/g, ' ').replace(/&nbsp;/gi, ' ').replace(/&amp;/gi, '&')
    .replace(/\s+/g, ' ').trim();
}

function candidateUrls(html, pageUrl, source) {
  const links = new Set([pageUrl]);
  const pattern = /href=["']([^"'#?][^"']*)["']/gi;
  for (const match of html.matchAll(pattern)) {
    try {
      const url = new URL(match[1].replace(/&amp;/g, '&'), pageUrl);
      if (url.protocol === 'https:' && SOURCES[source].allowedHosts.includes(url.hostname.toLowerCase()) &&
          /(newsdetail|news|detail|article)/i.test(url.pathname)) links.add(url.href);
    } catch (_) {
      // Ignore malformed links from publisher pages.
    }
  }
  return [...links].slice(0, 10);
}

function findHijriMonth(text) {
  const compact = text.toLowerCase().replace(/[’']/g, '').replace(/[-_]/g, ' ').replace(/\s+/g, ' ');
  for (const [name, number] of Object.entries(MONTHS)) {
    if (compact.includes(name.replace(/-/g, ' '))) return number;
  }
  return undefined;
}

function findGregorianDate(text, fallbackYear) {
  const monthNames = 'January|February|March|April|May|June|July|August|September|October|November|December';
  const first = text.match(new RegExp(`\\b(${monthNames})\\s+(\\d{1,2})(?:st|nd|rd|th)?(?:,?\\s+(\\d{4}))?`, 'i'));
  const second = text.match(new RegExp(`\\b(\\d{1,2})(?:st|nd|rd|th)?\\s+(${monthNames})(?:,?\\s+(\\d{4}))?`, 'i'));
  const match = first || second;
  if (!match) return undefined;
  const month = first ? match[1] : match[2];
  const day = Number(first ? match[2] : match[1]);
  const year = Number(first ? match[3] : match[3]) || fallbackYear;
  const date = new Date(`${month} ${day}, ${year} 12:00:00 UTC`);
  if (Number.isNaN(date.getTime())) return undefined;
  return date.toISOString().slice(0, 10);
}

function findExplicitMonthStartDate(text, fallbackYear) {
  const sentences = text.match(/[^.!?]+[.!?]+|[^.!?]+$/g) || [text];
  for (const sentence of sentences) {
    const identifiesFirstDay = /\b(?:1st|first)\s+(?:day\s+of\s+)?[a-z-]+\b/i.test(sentence);
    const statesStart = /\b(?:will\s+)?(?:fall|commence|begin|start)\b/i.test(sentence);
    if (!identifiesFirstDay || !statesStart) continue;
    const date = findGregorianDate(sentence, fallbackYear);
    if (date) return date;
  }
  return undefined;
}

function publishedAt(html) {
  const tag = html.match(
    /<meta\b[^>]*(?:article:published_time|datePublished)[^>]*>/i,
  )?.[0];
  const value = tag?.match(/\bcontent=["']([^"']+)["']/i)?.[1];
  return value && !Number.isNaN(Date.parse(value)) ? new Date(value).toISOString() : undefined;
}

export function parseAnnouncement(html, url, source) {
  const text = plainText(html);
  if (!/(central\s+ruet[ -]?e[ -]?hilal\s+committee)/i.test(text) ||
      !/(moon|crescent|hilal|sighted|not sighted)/i.test(text)) return undefined;
  const month = findHijriMonth(text);
  const hijriYear = Number(text.match(/\b(14\d{2})\s*(?:AH|Hijri)?\b/i)?.[1]);
  const announcedAt = publishedAt(html);
  const fallbackYear = announcedAt ? new Date(announcedAt).getUTCFullYear() : undefined;
  // A publication date or another date in the article is not evidence that a
  // Hijri month starts on that date. Only accept a date stated alongside the
  // explicit first-day announcement; otherwise leave the record unpublished.
  const startsOn = fallbackYear ? findExplicitMonthStartDate(text, fallbackYear) : undefined;
  if (!month || !Number.isInteger(hijriYear) || !startsOn || !announcedAt) return undefined;
  return {
    hijriYear,
    hijriMonth: month,
    startsOn,
    announcedAt,
    authorityName: 'Central Ruet-e-Hilal Committee Pakistan',
    sourceUrl: url,
    countryCode: 'PK',
    status: 'confirmed',
    source,
  };
}

async function fetchHtml(url) {
  const response = await fetch(url, { headers: { 'User-Agent': 'Islamic-Occasion-Planner/1.0', Accept: 'text/html' }, signal: AbortSignal.timeout(2_500) });
  if (!response.ok) throw new Error(`Publisher returned ${response.status}.`);
  return response.text();
}

export async function latestRecord(source) {
  const config = SOURCES[source];
  if (!config) throw new Error('Unknown source.');
  const indexHtml = await fetchHtml(config.discoveryUrl);
  const candidates = candidateUrls(indexHtml, config.discoveryUrl, source);
  const records = await Promise.all(candidates.map(async (url) => {
    try {
      const html = url === config.discoveryUrl ? indexHtml : await fetchHtml(url);
      return parseAnnouncement(html, url, source);
    } catch (_) {
      return undefined;
    }
  }));
  return records.find(Boolean);
}

import { latestRecord } from './_lib/hijri.js';

export default async function handler(_request, response) {
  try {
    const data = await latestRecord('mora');
    if (!data) return response.status(404).json({ error: 'No parseable official MoRA announcement is available.' });
    return response.status(200).json({ data });
  } catch (error) {
    return response.status(503).json({ error: error instanceof Error ? error.message : 'MoRA source unavailable.' });
  }
}

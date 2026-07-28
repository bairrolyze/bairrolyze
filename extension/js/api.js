// HomeScope – API Service
// Mirrors the Dio-based api_service.dart exactly.

const CONNECT_TIMEOUT = 30_000;
const RECEIVE_TIMEOUT = 90_000;

export class ApiService {
  constructor(baseUrl) {
    this.baseUrl = baseUrl.replace(/\/$/, '');
  }

  async analyzeAddress({ address, countryCode, profile = 'default', radius = 2000 }) {
    return this._post('/api/v1/analyze', { address, country_code: countryCode, profile, radius });
  }

  async geocode(address, countryCode) {
    return this._post('/api/v1/geocode', { address, country_code: countryCode });
  }

  async _post(path, body) {
    const controller = new AbortController();
    const connectTimer = setTimeout(() => controller.abort(), CONNECT_TIMEOUT);

    let res;
    try {
      res = await fetch(`${this.baseUrl}${path}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
        signal: controller.signal,
      });
    } catch (err) {
      if (err.name === 'AbortError') throw new ApiError('Connection timed out. Is the backend running?', 0);
      throw new ApiError(`Cannot connect to server: ${err.message}`, 0);
    } finally {
      clearTimeout(connectTimer);
    }

    let data;
    try {
      data = await res.json();
    } catch {
      throw new ApiError('Invalid response from server.', res.status);
    }

    if (!res.ok) {
      const msg = data?.detail || data?.message || `Server error ${res.status}`;
      if (res.status === 404) throw new ApiError('Address not found. Please check and try again.', 404);
      throw new ApiError(msg, res.status);
    }

    return data;
  }
}

export class ApiError extends Error {
  constructor(message, status) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
  }
}

# Artist Song Lookup

## Setup Instructions

### Prerequisites

- Ruby 3.4+ and Rails 8.0+
- Node.js (v18+ recommended)
- Yarn
- PostgreSQL
- Redis (for caching API responses)

### 1. Install dependencies

```bash
bundle install
yarn install --cwd frontend
```

### 2. Database setup

```bash
bin/rails db:setup
```

### 3. Vite/React build

```bash
yarn build --cwd frontend
```

### 4. Set Genius API Secrets

Set the following environment variables in your shell (example for bash/zsh):

```bash
export GENIUS_CLIENT_ID=your_client_id
export GENIUS_CLIENT_SECRET=your_client_secret
export GENIUS_REDIRECT_URI=http://localhost:3000/callback
```

Or add them to a `.env` file if you use dotenv or similar.

- `GENIUS_CLIENT_ID`
- `GENIUS_CLIENT_SECRET`
- `GENIUS_REDIRECT_URI` (should be `http://localhost:3000/callback` for local dev)

**TODO:** Move these secrets to a secure vault or secret manager for production use.


### 5. Running the backend (Rails API)

```bash
bin/rails server
```

### 6. Running the frontend (React app)

In a separate terminal, start the frontend development server:

```bash
cd frontend
yarn dev
```

This will start the React app at [http://localhost:5173](http://localhost:5173) by default.

The frontend will automatically proxy API and authentication requests to the Rails backend.

---

**Accessing the app:**

- Open [http://localhost:5173](http://localhost:3000) in your browser to use the Artist Song Lookup frontend.
- If you are not logged in with Genius, you will see a "Log in with Genius" button. Click it to start the OAuth process.
- After authenticating, you will be redirected to the search page where you can look up songs by artist name.

## API Usage

### Artist Song Lookup Endpoint

**Endpoint:**

```
GET http://localhost:3000/api/v1/artists/search?q=ARTIST_NAME
```

**Query Parameters:**

- `q` (required): Artist name to search for (case-insensitive)

**Example Request:**

```bash
curl -X GET "http://localhost:3000/api/v1/artists/search?q=kendrick+lamar" \
  --cookie "_artist_song_lookup_session=PASTE_YOUR_COOKIE_VALUE_HERE"
```

### How to get your session cookie (for API/curl usage)

1. Authenticate with Genius via your browser: [http://localhost:3000/auth/genius](http://localhost:3000/auth/genius)
2. Open browser dev tools (F12), go to the Application/Storage tab, and find Cookies for `http://localhost:3000`.
3. Copy the value of the `_artist_song_lookup_session` cookie.
4. Paste it in the curl command above.

**Note:** The session cookie is set as `HttpOnly` for security, so it is not accessible via JavaScript (`document.cookie`). The frontend determines authentication status by calling the backend endpoint `/api/v1/session`, which checks the session on the server. The curl instructions above are for manual API testing only.

**Example Response:**

```json
{
  "success": true,
  "data": {
    "artist_name": "kendrick lamar",
    "genius_artist_id": "1234",
    "songs": [
      "HUMBLE.",
      "DNA.",
      "Alright"
    ]
  }
}
```

**Error Responses:**

- `400 Bad Request`: `{ "error": "Missing or invalid artist name" }`
- `404 Not Found`: `{ "error": "Artist not found" }`
- `502 Bad Gateway`: `{ "error": "Genius API error: Timeout::Error - execution expired" }`

### Backend Resilience

The backend will automatically retry transient Genius API errors (such as timeouts or network errors) up to 3 times before returning a 502 error. This improves reliability for users and reduces the chance of a failed lookup due to temporary issues with the Genius API.

### Caching

Artist song lookups are cached in Redis for 10 minutes by artist name. No manual cache busting is required; cache expiration is handled automatically.

---

## Real-Time Streaming (ActionCable)

This app supports real-time streaming of large artist song lists using Rails ActionCable and WebSockets. When you search for an artist, results are streamed to the frontend as they are fetched, so you see songs appear incrementally instead of waiting for the full list.

**How it works:**
- The frontend sends a POST request to `/api/v1/artists/stream_songs` with the artist name.
- The backend starts a background job to fetch songs from Genius (with retries and pagination).
- As each page of results is fetched, the backend broadcasts the new songs to a unique ActionCable channel for your search.
- The React frontend subscribes to this channel and renders results as they arrive.

**Requirements:**
- Redis must be running (used for both ActionCable and caching).
- The Rails server must be started with ActionCable enabled (default for Rails 8).
- The frontend must connect to the correct WebSocket URL (see `frontend/src/consumer.js`).

**Troubleshooting:**
- If you see a spinner forever, check that Redis is running and that the frontend is connecting to `ws://localhost:3000/cable`.
- If you see errors about `uninitialized constant ApplicationCable`, make sure you have the standard `app/channels/application_cable/channel.rb` and `connection.rb` files.
- If you see errors about Redis types, ensure you do not assign a Redis client instance to a constant named `Redis` or `RedisClient`.

---

## Testing

To run the test suite:

```bash
bundle exec rspec
```

**Note:**
- Specs mock the `$redis_client` global for Redis interactions. If you change the Redis client name, update the specs accordingly.
- The test suite uses RSpec and WebMock for HTTP stubbing.

---

## Environment Variables

- `GENIUS_CLIENT_ID`, `GENIUS_CLIENT_SECRET`, `GENIUS_REDIRECT_URI` (see above)
- `REDIS_URL` (optional, defaults to `redis://localhost:6379/0`)

---

## Notes

- This project uses Rails 8, React 18 (Vite), Redis, and ActionCable.
- For any issues, check the logs in `log/development.log` and browser console for WebSocket errors.

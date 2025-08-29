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

### 5. Running the app

```bash
bin/rails server
```

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

### How to get your session cookie

1. Authenticate with Genius via your browser: [http://localhost:3000/auth/genius](http://localhost:3000/auth/genius)
2. Open browser dev tools (F12), go to the Application/Storage tab, and find Cookies for `http://localhost:3000`.
3. Copy the value of the `_artist_song_lookup_session` cookie.
4. Paste it in the curl command above.

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

Visit [http://localhost:3000](http://localhost:3000)

---

For development with hot reloading, run `yarn dev` in the `frontend` directory and proxy API requests to Rails as needed.

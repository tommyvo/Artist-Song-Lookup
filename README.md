# Artist-Song-Lookup

## Setup Instructions

### Prerequisites

- Ruby 3.4+ and Rails 8.0+
- Node.js (v18+ recommended)
- Yarn
- PostgreSQL

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

### 6. API Usage

#### Artist Search Endpoint

**Endpoint:**

```
GET http://localhost:3000/api/v1/artists/search
```

**Query Parameters:**

- `q` (required): Artist name to search for
- `page` (optional): Page number (default: 1)
- `per_page` (optional): Results per page (default: 10)

**Authentication:**

- Requires a valid Genius OAuth access token in the session (obtain via `/auth/genius` flow)

**Example Request:**

```bash
curl -X GET "http://localhost:3000/api/v1/artists/search?q=adele&page=1&per_page=5" \
  --cookie "_artist_song_lookup_session=PASTE_YOUR_COOKIE_VALUE_HERE"
```

#### How to Get Your Session Cookie

1. Authenticate with Genius via your browser: [http://localhost:3000/auth/genius](http://localhost:3000/auth/genius)
2. Open browser dev tools (F12), go to the Application/Storage tab, and find Cookies for `http://localhost:3000`.
3. Copy the value of the `_artist_song_lookup_session` cookie.
4. Paste it in the curl command above.

**Example Response:**


```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Adele",
      ...
    },
    {
      "id": 2,
      "name": "Adele Givens",
      ...
    }
  ],
  "error": null,
  "pagination": {
    "page": 1,
    "per_page": 5,
    "total": 12,
    "total_pages": 3
  }
}
```


**Response Structure:**

- `success` (boolean): Indicates if the request was successful
- `data` (array): Array of artist objects (empty if error)
- `error` (string or null): Error message if any, otherwise null
- `pagination` (object): Pagination metadata (empty object if error)

**Error Responses:**

- `401 Unauthorized`: Not authenticated with Genius
  - Example: `{ "success": false, "data": [], "error": "Not authenticated with Genius", "pagination": {} }`
- `400 Bad Request`: Missing or invalid parameters
  - Example: `{ "success": false, "data": [], "error": "Missing artist name", "pagination": {} }`

- `502 Bad Gateway`: Genius API error, timeout, or rate limit
  - Example (timeout): `{ "success": false, "data": [], "error": "The request to Genius timed out. Please try again later.", "pagination": {} }`
  - Example (unexpected error): `{ "success": false, "data": [], "error": "An unexpected error occurred while contacting Genius. Please try again later.", "pagination": {} }`

---

Visit [http://localhost:3000](http://localhost:3000)

---

For development with hot reloading, run `yarn dev` in the `frontend` directory and proxy API requests to Rails as needed.

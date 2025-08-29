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

- Open [http://localhost:5173](http://localhost:5173) in your browser to use the Artist Song Lookup frontend.
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
curl -X GET "http://localhost:3000/api/v1/artists/search?q=adele" \
  -H "Authorization: Bearer YOUR_GENIUS_ACCESS_TOKEN"
```

### How to get your Genius access token

1. Authenticate with Genius via your browser: [http://localhost:3000/auth/genius](http://localhost:3000/auth/genius)
2. **If you are running in the development environment, the access token will be displayed in the OAuth success message after authentication. You can copy it directly from there.**
3. In other environments, your access token will be stored in your Rails session or may be available via your app's implementation.
4. Use the access token in the `Authorization` header as shown above.

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

## Development Workflow

**Frontend development (hot reloading):**

- Run `yarn dev` in the `frontend` directory and open [http://localhost:5173](http://localhost:5173) for fast UI development with hot reloading. (Session cookies may not work due to cross-origin restrictions.)

**Full integration testing (backend + cookies):**

- After making frontend changes, run `yarn build` in the `frontend` directory.
- Access your app at [http://localhost:3000](http://localhost:3000) (served by Rails) to test authentication, cookies, and backend integration. (No hot reloading.)

This is the recommended workflow for Rails + Vite projects.

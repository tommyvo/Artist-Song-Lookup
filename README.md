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
Visit [http://localhost:3000](http://localhost:3000)

---
For development with hot reloading, run `yarn dev` in the `frontend` directory and proxy API requests to Rails as needed.

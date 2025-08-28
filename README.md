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

### 4. Running the app
```bash
bin/rails server
```
Visit [http://localhost:3000](http://localhost:3000)

---
For development with hot reloading, run `yarn dev` in the `frontend` directory and proxy API requests to Rails as needed.

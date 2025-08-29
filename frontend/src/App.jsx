import React, { useEffect, useState } from 'react';
import SearchPage from './SearchPage';

export default function App() {
  const [authenticated, setAuthenticated] = useState(null);

  useEffect(() => {
    fetch('/api/v1/session')
      .then(res => res.ok ? res.json() : { authenticated: false })
      .then(data => setAuthenticated(!!data.authenticated))
      .catch(() => setAuthenticated(false));
  }, []);

  if (authenticated === null) {
    return null; // or a loading spinner
  }

  if (!authenticated) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column' }}>
        <h2>Artist Song Lookup</h2>
        <a href="/auth/genius" style={{ fontSize: 20, padding: '12px 24px', background: '#fffc', borderRadius: 8, textDecoration: 'none', color: '#222', fontWeight: 600 }}>
          Log in with Genius
        </a>
      </div>
    );
  }

  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <SearchPage />
    </div>
  );
}

import React, { useEffect, useState } from 'react';
import SearchPage from './SearchPage';

function Spinner() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', margin: 24 }}>
      <span className="spinner" />
      <div style={{ marginTop: 12, fontSize: 16, color: '#555' }}>Please wait…</div>
    </div>
  );
}

function Toast({ message, onClose }) {
  if (!message) return null;
  return (
    <div className="toast" onClick={onClose}>
      {message}
      <span style={{ marginLeft: 12, cursor: 'pointer', fontWeight: 700 }}>&times;</span>
    </div>
  );
}

export default function App() {
  const [authenticated, setAuthenticated] = useState(null);
  const [globalLoading, setGlobalLoading] = useState(false);
  const [globalError, setGlobalError] = useState("");

  useEffect(() => {
    setGlobalLoading(true);
    fetch('/api/v1/session')
      .then(res => res.ok ? res.json() : { authenticated: false })
      .then(data => setAuthenticated(!!data.authenticated))
      .catch(() => {
        setAuthenticated(false);
        setGlobalError("Failed to check authentication. Please try again.");
      })
      .finally(() => setGlobalLoading(false));
  }, []);

  // Optionally, you can pass setGlobalLoading and setGlobalError to children for deeper error/loading handling

  return (
    <>
      {globalLoading && <Spinner />}
      <Toast message={globalError} onClose={() => setGlobalError("")} />
      {authenticated === null && !globalLoading ? null :
        !authenticated ? (
          <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column' }}>
            <h2>Artist Song Lookup</h2>
            <a href="/auth/genius" style={{ fontSize: 20, padding: '12px 24px', background: '#fffc', borderRadius: 8, textDecoration: 'none', color: '#222', fontWeight: 600 }}>
              Log in with Genius
            </a>
          </div>
        ) : (
          <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <SearchPage setGlobalError={setGlobalError} />
          </div>
        )
      }
    </>
  );
}

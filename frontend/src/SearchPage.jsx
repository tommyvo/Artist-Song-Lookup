import React, { useState } from 'react';

function Spinner() {
  return <div style={{ margin: 24 }}><span className="spinner" /></div>;
}

export default function SearchPage({ token }) {
  const [artist, setArtist] = useState('');
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleSearch = async (e) => {
    e.preventDefault();
    setResults(null);
    setError(null);
    setLoading(true);
    let attempts = 0;
    let lastError = null;
    while (attempts < 3) {
      try {
        const res = await fetch(`/api/v1/artists/search?q=${encodeURIComponent(artist)}`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (res.ok) {
          const data = await res.json();
          setResults(data.data.songs);
          setLoading(false);
          return;
        } else if (res.status === 404) {
          attempts++;
          lastError = 'Artist not found. Retrying...';
          await new Promise(r => setTimeout(r, 700));
        } else {
          lastError = `Error: ${res.status}`;
          break;
        }
      } catch (err) {
        lastError = err.message;
        break;
      }
    }
    setError(lastError || 'Failed to fetch results.');
    setLoading(false);
  };

  return (
    <div>
      <form onSubmit={handleSearch} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', minWidth: 320 }}>
        <h2>Search for an Artist</h2>
        <input
          type="text"
          value={artist}
          onChange={e => setArtist(e.target.value)}
          placeholder="Enter artist name"
          style={{ fontSize: 18, padding: 10, margin: '16px 0', width: 250, borderRadius: 6, border: '1px solid #ccc' }}
          required
        />
        <button type="submit" style={{ fontSize: 18, padding: '8px 24px', borderRadius: 6, background: '#222', color: '#fff', border: 'none', fontWeight: 600 }} disabled={loading}>
          Search
        </button>
      </form>
      {loading && <Spinner />}
      {error && <div style={{ color: 'red', marginTop: 16 }}>{error}</div>}
      {results && (
        <div style={{ marginTop: 32, textAlign: 'center' }}>
          <h3>Results</h3>
          <ul style={{ listStyle: 'none', padding: 0 }}>
            {results.map((song, i) => (
              <li key={i} style={{ fontSize: 18, margin: '8px 0' }}>{song}</li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}

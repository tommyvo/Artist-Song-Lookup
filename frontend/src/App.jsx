import React from 'react';
import SearchPage from './SearchPage';

export default function App() {
  // You can add logic here for authentication if needed
  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <SearchPage token={null} />
    </div>
  );
}

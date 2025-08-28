import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: resolve(__dirname, '../public/vite'),
    emptyOutDir: true,
    manifest: true,
  },
  base: '/vite/', // This will prefix built assets with /vite/
});

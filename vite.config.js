import { fileURLToPath } from 'node:url';
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

const root = fileURLToPath(new URL('.', import.meta.url));

// The analysis workspace ships as its own build (dist-app) with app.html as
// the entry, so it can be deployed independently on the app subdomain.
function renameAppEntry() {
  return {
    name: 'sidar-rename-app-entry',
    enforce: 'post',
    generateBundle(_, bundle) {
      const entry = bundle['app.html'];
      if (!entry) return;
      delete bundle['app.html'];
      entry.fileName = 'index.html';
      bundle['index.html'] = entry;
    },
  };
}

export default defineConfig(({ mode }) => {
  const isAnalysis = mode === 'analysis';
  return {
    plugins: [react(), ...(isAnalysis ? [renameAppEntry()] : [])],
    build: isAnalysis
      ? {
          outDir: 'dist-app',
          emptyOutDir: true,
          rollupOptions: { input: `${root}app.html` },
        }
      : {},
  };
});

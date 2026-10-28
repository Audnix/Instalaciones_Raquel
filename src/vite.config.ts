import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    proxy: {
      "/api": "http://127.0.0.1:4000",
      "/health": "http://127.0.0.1:4000"
    }
  },
  build: {
    chunkSizeWarningLimit: 1200,
    rollupOptions: {
      output: {
        manualChunks: {
          charts: ["recharts"],
          motion: ["framer-motion"],
          forms: ["react-hook-form", "zod", "@hookform/resolvers"]
        }
      }
    }
  }
});

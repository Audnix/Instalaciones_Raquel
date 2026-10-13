/** @type {import('tailwindcss').Config} */
export default {
  darkMode: "class",
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter", "ui-sans-serif", "system-ui", "Segoe UI", "sans-serif"]
      },
      colors: {
        brand: {
          50: "#edfaff",
          100: "#d6f4ff",
          500: "#0a92c8",
          600: "#0877a4",
          700: "#0b5f83",
          900: "#09324a"
        },
        alloy: "#9aa8b5",
        glass: "#72d4ef",
        ember: "#e84b5f",
        moss: "#2f9b73",
        ink: "#152033"
      },
      boxShadow: {
        soft: "0 18px 60px rgba(12, 39, 66, 0.14)",
        glow: "0 0 0 1px rgba(114, 212, 239, 0.22), 0 24px 70px rgba(8, 119, 164, 0.22)"
      }
    }
  },
  plugins: []
};

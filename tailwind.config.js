/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./components/**/*.{js,vue,ts}",
    "./layouts/**/*.vue",
    "./pages/**/*.vue",
    "./plugins/**/*.{js,ts}",
    "./app.vue",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Montserrat', 'sans-serif'],
      },
    },
  },
  plugins: [require("daisyui")],
  daisyui: {
    themes: [
      {
        redblack: {
          "primary": "#dc2626",        // Rouge vif
          "secondary": "#991b1b",      // Rouge foncé
          "accent": "#ef4444",         // Rouge accent
          "neutral": "#1f1f1f",        // Noir gris
          "base-100": "#0a0a0a",       // Noir profond
          "base-200": "#171717",       // Noir moins profond
          "base-300": "#262626",       // Gris très foncé
          "info": "#ef4444",           // Rouge pour info
          "success": "#16a34a",        // Vert pour succès
          "warning": "#f59e0b",        // Orange pour warning
          "error": "#dc2626",          // Rouge pour erreur
        },
      },
    ],
  },
}

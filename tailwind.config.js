/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./app/views/**/*.html.erb",
    "./resources/js/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        fleet: {
          50: '#eff8f1',
          100: '#d9efdf',
          200: '#b4dfc0',
          300: '#81c89a',
          400: '#4bae6b',
          500: '#278e4b',
          600: '#1b713b',
          700: '#185a32',
          800: '#16482a',
          900: '#123b25',
          950: '#092116',
        },
        slate: {
          850: '#151e2e',
          900: '#0f172a',
          950: '#080d1a',
        }
      },
      fontFamily: {
        sans: ['IBM Plex Sans', 'sans-serif'],
        display: ['Barlow Condensed', 'sans-serif'],
      }
    },
  },
  plugins: [],
}

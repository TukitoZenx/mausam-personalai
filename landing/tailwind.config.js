/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        obsidian: {
          950: '#08080A', // Root deep base
          900: '#09090B', // Secondary deep
          850: '#0C0C0E', // Main scaffold bg
          800: '#141417', // Elevated surface
          750: '#18181B', // Primary card fill
          700: '#202024', // Card hover state
          600: '#27272A', // Hairline 1px border
          500: '#3F3F46',
          400: '#71717A', // Muted metadata
          300: '#A1A1AA', // Medium emphasis
          200: '#D4D4D8', // High emphasis silver
          100: '#FAFAFA', // Pure white text
        },
        persona: {
          fitness: '#FAFAFA',
          health: '#D4D4D8',
          traveler: '#A1A1AA',
          commuter: '#38BDF8',
          family: '#F472B6',
          garden: '#34D399',
          events: '#F59E0B',
          golden: '#FBBF24',
        }
      },
      fontFamily: {
        serif: ['"Instrument Serif"', 'Georgia', 'serif'],
        sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'sans-serif'],
      },
      borderRadius: {
        '24': '24px',
        '28': '28px',
        '32': '32px',
      },
      backdropBlur: {
        '24': '24px',
      },
      animation: {
        'fade-up': 'fadeUp 600ms cubic-bezier(0.16, 1, 0.3, 1) forwards',
        'pulse-subtle': 'pulseSubtle 4s ease-in-out infinite',
      },
      keyframes: {
        fadeUp: {
          '0%': { opacity: '0', transform: 'translateY(16px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        pulseSubtle: {
          '0%, 100%': { opacity: '0.6', transform: 'scale(1)' },
          '50%': { opacity: '0.9', transform: 'scale(1.03)' },
        },
      },
    },
  },
  plugins: [],
}

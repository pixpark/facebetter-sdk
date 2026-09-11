/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Geist', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'ui-monospace', 'monospace'],
      },
      fontSize: {
        'headline-sm': ['14px', { lineHeight: '20px', letterSpacing: '-0.01em', fontWeight: '600' }],
        'body-sm': ['11px', { lineHeight: '14px' }],
        'body-md': ['12px', { lineHeight: '16px' }],
        'label-sm': ['10px', { lineHeight: '12px', letterSpacing: '0.02em', fontWeight: '500' }],
        'telemetry-xs': ['9px', { lineHeight: '11px', letterSpacing: '0.04em' }],
      },
    },
  },
  plugins: [],
}

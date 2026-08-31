/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        ink: {
          950: '#0a0a0f',
          900: '#121218',
          850: '#17171f',
          800: '#1c1c26',
          700: '#26262f',
          600: '#34343f',
          500: '#4a4a58',
          400: '#6b6b7d',
          300: '#9494a3',
        },
      },
      boxShadow: {
        glow: '0 0 0 1px rgba(99,102,241,0.45), 0 8px 30px -6px rgba(99,102,241,0.45)',
        card: '0 1px 0 0 rgba(255,255,255,0.04) inset, 0 8px 24px -12px rgba(0,0,0,0.6)',
      },
      backgroundImage: {
        'grid-fade':
          'radial-gradient(circle at 20% 20%, rgba(99,102,241,0.18), transparent 40%), radial-gradient(circle at 80% 0%, rgba(168,85,247,0.14), transparent 45%)',
      },
      keyframes: {
        blob: {
          '0%, 100%': { transform: 'translate(0px, 0px) scale(1)' },
          '33%': { transform: 'translate(20px, -30px) scale(1.08)' },
          '66%': { transform: 'translate(-15px, 15px) scale(0.95)' },
        },
        fadeIn: {
          from: { opacity: 0, transform: 'translateY(4px)' },
          to: { opacity: 1, transform: 'translateY(0)' },
        },
        fadeInUp: {
          from: { opacity: 0, transform: 'translateY(10px)' },
          to: { opacity: 1, transform: 'translateY(0)' },
        },
      },
      animation: {
        blob: 'blob 12s infinite ease-in-out',
        fadeIn: 'fadeIn 0.18s ease-out',
        fadeInUp: 'fadeInUp 0.5s ease-out both',
      },
    },
  },
  plugins: [],
}

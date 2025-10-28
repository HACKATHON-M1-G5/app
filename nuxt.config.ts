// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2024-04-03',
  devtools: { enabled: true },

  modules: [
    '@nuxtjs/supabase',
    '@nuxtjs/tailwindcss',
    '@pinia/nuxt',
    '@nuxtjs/color-mode',
    '@nuxtjs/google-fonts',
  ],

  googleFonts: {
    families: {
      Montserrat: [300, 400, 500, 600, 700, 800, 900],
    },
    display: 'swap',
  },

  supabase: {
    redirect: false,
    redirectOptions: {
      login: '/login',
      callback: '/confirm',
      exclude: ['/register', '/'],
    },
  },

  colorMode: {
    classSuffix: '',
    preference: 'redblack',
    dataValue: 'redblack',
  },

  runtimeConfig: {
    public: {
      supabaseUrl: process.env.SUPABASE_URL,
      supabaseKey: process.env.SUPABASE_KEY,
    },
  },

  css: ['~/assets/css/main.css'],

  typescript: {
    strict: true,
    typeCheck: false,
  },

  // Add app head so we can set the favicon to the logo asset (Vite resolves the URL)
  app: {
    head: {
      title: 'LoseAMax',
      link: [
        {
          rel: 'icon',
          type: 'image/png',
          // Use Vite import resolution so the asset path is correct in dev and production
          href: '_nuxt/assets/favicon.ico'
        },
      ],
    },
  },

  nitro: {
    experimental: {
      websocket: true,
    },
  },

  vite: {
    server: {
      hmr: {
        clientPort: 3000,
      },
    },
  },
})

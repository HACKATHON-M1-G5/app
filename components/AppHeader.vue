<template>
  <header class="navbar bg-base-100 shadow-lg sticky top-0 z-50">
    <div class="navbar-start">
      <div class="dropdown">
        <label tabindex="0" class="btn btn-ghost lg:hidden">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M4 6h16M4 12h8m-8 6h16"
            />
          </svg>
        </label>
        <ul
          tabindex="0"
          class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52"
        >
          <li><NuxtLink to="/">Accueil</NuxtLink></li>
          <li><NuxtLink to="/groups">Mes Groupes</NuxtLink></li>
          <li><NuxtLink to="/public-bets">Paris Publics</NuxtLink></li>
          <li><NuxtLink to="/groups/create">Créer un Groupe</NuxtLink></li>
        </ul>
      </div>
      <NuxtLink to="/" class="btn btn-ghost normal-case text-xl font-bold tracking-tight">
        <span class="text-red-600">🎲</span>
        <span class="bg-gradient-to-r from-red-600 to-red-500 bg-clip-text text-transparent"
          >LoseAMax</span
        >
      </NuxtLink>
    </div>

    <div class="navbar-center hidden lg:flex">
      <ul class="menu menu-horizontal px-1">
        <li><NuxtLink to="/">Accueil</NuxtLink></li>
        <li><NuxtLink to="/groups">Mes Groupes</NuxtLink></li>
        <li><NuxtLink to="/public-bets">Paris Publics</NuxtLink></li>
        <li><NuxtLink to="/groups/create">Créer un Groupe</NuxtLink></li>
      </ul>
    </div>

    <div class="navbar-end gap-2">
      <div v-if="userData" class="flex items-center gap-4">
        <div class="badge badge-primary badge-lg">💰 {{ userData.tokens }} tokens</div>
        <div class="dropdown dropdown-end">
          <label tabindex="0" class="btn btn-ghost btn-circle avatar placeholder">
            <div class="bg-neutral-focus text-neutral-content rounded-full w-10">
              <span class="text-xl">{{ userData.username[0].toUpperCase() }}</span>
            </div>
          </label>
          <ul
            tabindex="0"
            class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52"
          >
            <li>
              <NuxtLink to="/profile" class="justify-between">
                Profil
                <span class="badge">{{ (userData.winrate * 100).toFixed(0) }}%</span>
              </NuxtLink>
            </li>
            <li><a @click="handleLogout">Déconnexion</a></li>
          </ul>
        </div>
      </div>
      <div v-else class="flex gap-2">
        <NuxtLink to="/login" class="btn btn-ghost btn-sm"> Connexion </NuxtLink>
        <NuxtLink to="/register" class="btn btn-primary btn-sm"> Inscription </NuxtLink>
      </div>
    </div>
  </header>
</template>

<script setup lang="ts">
const supabase = useSupabaseClient()
const { userData } = useUserData()

const handleLogout = async () => {
  await supabase.auth.signOut()
  await navigateTo('/login')
}
</script>

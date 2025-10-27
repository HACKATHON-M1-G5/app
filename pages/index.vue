<template>
  <div class="container mx-auto px-4 py-8">
    <!-- Hero Section -->
    <div class="hero bg-base-100 shadow-xl rounded-box mb-8">
      <div class="hero-content text-center py-12">
        <div class="max-w-2xl">
          <h1 class="text-5xl font-bold mb-4">🎲 Bienvenue sur PronosBet</h1>
          <p class="text-xl mb-8">
            Créez des paris entre amis, rejoignez des groupes et tentez de gagner un maximum de tokens !
          </p>
          
          <div v-if="!user" class="flex gap-4 justify-center">
            <NuxtLink to="/register" class="btn btn-primary btn-lg">
              Commencer maintenant
            </NuxtLink>
            <NuxtLink to="/login" class="btn btn-outline btn-lg">
              Se connecter
            </NuxtLink>
          </div>
        </div>
      </div>
    </div>

    <!-- Dashboard pour utilisateurs connectés -->
    <div v-if="user && userData">
      <!-- Statistiques utilisateur -->
      <div class="stats stats-vertical lg:stats-horizontal shadow w-full mb-8">
        <div class="stat">
          <div class="stat-figure text-primary">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"></path>
            </svg>
          </div>
          <div class="stat-title">Tokens Globaux</div>
          <div class="stat-value text-primary">{{ userData.tokens }}</div>
          <div class="stat-desc">Pour les paris publics</div>
        </div>
        
        <div class="stat">
          <div class="stat-figure text-secondary">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
            </svg>
          </div>
          <div class="stat-title">Taux de réussite</div>
          <div class="stat-value text-secondary">{{ (userData.winrate * 100).toFixed(1) }}%</div>
          <div class="stat-desc">Vos paris gagnants</div>
        </div>
        
        <div class="stat">
          <div class="stat-figure text-accent">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
            </svg>
          </div>
          <div class="stat-title">Mes Groupes</div>
          <div class="stat-value text-accent">{{ myTeams.length }}</div>
          <div class="stat-desc">Groupes rejoints</div>
        </div>

        <div class="stat">
          <div class="stat-figure text-info">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
            </svg>
          </div>
          <div class="stat-title">Paris Actifs</div>
          <div class="stat-value text-info">{{ activeBets.length }}</div>
          <div class="stat-desc">En cours</div>
        </div>
      </div>

      <!-- Actions rapides -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        <NuxtLink to="/groups/create" class="card bg-primary text-primary-content shadow-xl hover:shadow-2xl transition-shadow">
          <div class="card-body items-center text-center">
            <div class="text-5xl mb-2">➕</div>
            <h2 class="card-title">Créer un groupe</h2>
            <p>Créez votre propre groupe de paris</p>
          </div>
        </NuxtLink>
        
        <NuxtLink to="/groups" class="card bg-secondary text-secondary-content shadow-xl hover:shadow-2xl transition-shadow">
          <div class="card-body items-center text-center">
            <div class="text-5xl mb-2">🏆</div>
            <h2 class="card-title">Mes Groupes</h2>
            <p>Gérez vos groupes et paris</p>
          </div>
        </NuxtLink>
        
        <NuxtLink to="/public-bets" class="card bg-accent text-accent-content shadow-xl hover:shadow-2xl transition-shadow">
          <div class="card-body items-center text-center">
            <div class="text-5xl mb-2">🌍</div>
            <h2 class="card-title">Paris Publics</h2>
            <p>Participez aux paris publics</p>
          </div>
        </NuxtLink>
      </div>

      <!-- Paris publics récents -->
      <section class="mb-8">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-2xl font-bold">Paris Publics Récents</h2>
          <NuxtLink to="/public-bets" class="btn btn-ghost btn-sm">
            Voir tout →
          </NuxtLink>
        </div>
        
        <div v-if="loadingPublicPronos" class="flex justify-center py-8">
          <span class="loading loading-spinner loading-lg"></span>
        </div>
        
        <div v-else-if="publicPronos.length === 0" class="alert alert-info">
          <span>Aucun pari public disponible pour le moment.</span>
        </div>
        
        <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <PronoCard 
            v-for="prono in publicPronos.slice(0, 3)" 
            :key="prono.id" 
            :prono="prono"
          />
        </div>
      </section>

      <!-- Mes groupes -->
      <section v-if="myTeams.length > 0">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-2xl font-bold">Mes Groupes</h2>
          <NuxtLink to="/groups" class="btn btn-ghost btn-sm">
            Voir tout →
          </NuxtLink>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <GroupCard 
            v-for="team in myTeams.slice(0, 3)" 
            :key="team.id" 
            :team="team"
          />
        </div>
      </section>

      <!-- Mes paris actifs -->
      <section v-if="activeBets.length > 0" class="mt-8">
        <h2 class="text-2xl font-bold mb-4">Mes Paris Actifs</h2>
        
        <div class="space-y-4">
          <div 
            v-for="userBet in activeBets.slice(0, 5)" 
            :key="userBet.id"
            class="card bg-base-100 shadow-xl"
          >
            <div class="card-body">
              <div class="flex justify-between items-start">
                <div>
                  <h3 class="font-bold text-lg">{{ userBet.bet?.prono?.name }}</h3>
                  <p class="text-sm opacity-70 mt-1">Option : {{ userBet.bet?.title }}</p>
                  <p class="text-sm mt-1">Mise : {{ userBet.amount }} tokens</p>
                  <p class="text-sm text-success">Gain potentiel : {{ Math.floor(userBet.amount * (userBet.bet?.odds || 1)) }} tokens</p>
                </div>
                
                <NuxtLink 
                  :to="`/pronos/${userBet.bet?.prono?.id}`" 
                  class="btn btn-primary btn-sm"
                >
                  Voir
                </NuxtLink>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>

    <!-- Section pour utilisateurs non connectés -->
    <div v-else class="grid grid-cols-1 md:grid-cols-3 gap-8 mt-12">
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body items-center text-center">
          <div class="text-5xl mb-4">🏆</div>
          <h2 class="card-title">Créez des groupes</h2>
          <p>Organisez des paris entre amis dans des groupes privés ou publics</p>
        </div>
      </div>
      
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body items-center text-center">
          <div class="text-5xl mb-4">💰</div>
          <h2 class="card-title">Pariez avec des tokens</h2>
          <p>Utilisez vos tokens pour parier et tentez de maximiser vos gains</p>
        </div>
      </div>
      
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body items-center text-center">
          <div class="text-5xl mb-4">📊</div>
          <h2 class="card-title">Suivez vos stats</h2>
          <p>Consultez vos statistiques et votre taux de réussite</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Team, PronoWithBets, UserBetWithDetails } from '~/types/database'

const user = useSupabaseUser()
const { userData } = useUserData()
const { getMyTeams } = useTeams()
const { getPublicPronos } = usePronos()
const { getUserActiveBets } = useBets()

const myTeams = ref<Team[]>([])
const publicPronos = ref<PronoWithBets[]>([])
const activeBets = ref<UserBetWithDetails[]>([])
const loadingPublicPronos = ref(false)

watch(user, async (newUser) => {
  if (newUser) {
    await loadDashboardData()
  }
}, { immediate: true })

const loadDashboardData = async () => {
  if (!user.value) return

  loadingPublicPronos.value = true

  try {
    const [teams, pronos, bets] = await Promise.all([
      getMyTeams(),
      getPublicPronos(),
      getUserActiveBets()
    ])

    myTeams.value = teams
    publicPronos.value = pronos
    activeBets.value = bets
  } catch (e) {
    console.error('Error loading dashboard data:', e)
  } finally {
    loadingPublicPronos.value = false
  }
}
</script>


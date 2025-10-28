<template>
  <div class="container mx-auto px-4 py-8">
    <div class="flex flex-col md:flex-row md:items-center md:justify-between mb-8">
      <div>
        <h1 class="text-3xl md:text-4xl font-bold bg-gradient-to-r from-yellow-600 to-yellow-500 bg-clip-text text-transparent">
          🏆 Classement Général
        </h1>
        <p class="text-sm md:text-base opacity-70 mt-2">Les meilleurs joueurs classés par tokens globaux</p>
      </div>
      
      <div v-if="userData" class="mt-4 md:mt-0">
        <div class="stats shadow bg-base-200">
          <div class="stat py-3 px-4">
            <div class="stat-title text-xs">Votre position</div>
            <div class="stat-value text-2xl text-primary">
              {{ userRank > 0 ? `#${userRank}` : '-' }}
            </div>
            <div class="stat-desc text-xs">{{ userData.tokens }} tokens</div>
          </div>
        </div>
      </div>
    </div>

    <div v-if="loading" class="flex justify-center py-8">
      <span class="loading loading-spinner loading-lg"></span>
    </div>

    <div v-else class="space-y-6">
      <!-- Podium Top 3 -->
      <div v-if="rankedUsers.length >= 3" class="flex justify-center items-end gap-4 mb-8">
        <!-- 2ème place -->
        <div class="flex flex-col items-center">
          <div class="text-6xl mb-2">🥈</div>
          <div class="card bg-base-100 shadow-xl border-2 border-gray-400 w-36">
            <div class="card-body p-4 text-center">
              <div class="avatar placeholder mx-auto mb-2">
                <div class="bg-gray-400 text-white rounded-full w-16">
                  <span class="text-2xl">{{ rankedUsers[1].username[0].toUpperCase() }}</span>
                </div>
              </div>
              <h3 class="font-bold text-sm truncate" :title="rankedUsers[1].username">
                {{ rankedUsers[1].username }}
              </h3>
              <div class="badge badge-warning mt-1">{{ rankedUsers[1].tokens }} 🪙</div>
              <div class="text-xs opacity-70 mt-1">{{ (rankedUsers[1].winrate * 100).toFixed(0) }}% WR</div>
            </div>
          </div>
        </div>

        <!-- 1ère place -->
        <div class="flex flex-col items-center -mt-8">
          <div class="text-8xl mb-2">🥇</div>
          <div class="card bg-base-100 shadow-2xl border-4 border-yellow-500 w-40">
            <div class="card-body p-4 text-center">
              <div class="avatar placeholder mx-auto mb-2">
                <div class="bg-yellow-500 text-white rounded-full w-20">
                  <span class="text-3xl">{{ rankedUsers[0].username[0].toUpperCase() }}</span>
                </div>
              </div>
              <h3 class="font-bold truncate" :title="rankedUsers[0].username">
                {{ rankedUsers[0].username }}
              </h3>
              <div class="badge badge-warning badge-lg mt-1">{{ rankedUsers[0].tokens }} 🪙</div>
              <div class="text-xs opacity-70 mt-1">{{ (rankedUsers[0].winrate * 100).toFixed(0) }}% WR</div>
            </div>
          </div>
        </div>

        <!-- 3ème place -->
        <div class="flex flex-col items-center">
          <div class="text-6xl mb-2">🥉</div>
          <div class="card bg-base-100 shadow-xl border-2 border-orange-700 w-36">
            <div class="card-body p-4 text-center">
              <div class="avatar placeholder mx-auto mb-2">
                <div class="bg-orange-700 text-white rounded-full w-16">
                  <span class="text-2xl">{{ rankedUsers[2].username[0].toUpperCase() }}</span>
                </div>
              </div>
              <h3 class="font-bold text-sm truncate" :title="rankedUsers[2].username">
                {{ rankedUsers[2].username }}
              </h3>
              <div class="badge badge-warning mt-1">{{ rankedUsers[2].tokens }} 🪙</div>
              <div class="text-xs opacity-70 mt-1">{{ (rankedUsers[2].winrate * 100).toFixed(0) }}% WR</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Classement complet -->
      <div class="card bg-base-100 shadow-xl border border-red-900/30">
        <div class="card-body">
          <h2 class="card-title mb-4">Classement Complet</h2>
          
          <div class="overflow-x-auto">
            <table class="table">
              <thead>
                <tr>
                  <th>Rang</th>
                  <th>Joueur</th>
                  <th>Tokens</th>
                  <th>Winrate</th>
                </tr>
              </thead>
              <tbody>
                <tr 
                  v-for="(user, index) in rankedUsers" 
                  :key="user.id"
                  :class="{
                    'bg-yellow-500/10': index === 0,
                    'bg-gray-400/10': index === 1,
                    'bg-orange-700/10': index === 2,
                    'bg-primary/5': userData && user.id === userData.id && index > 2,
                  }"
                >
                  <td>
                    <div class="flex items-center gap-2">
                      <span v-if="index === 0" class="text-2xl">🥇</span>
                      <span v-else-if="index === 1" class="text-2xl">🥈</span>
                      <span v-else-if="index === 2" class="text-2xl">🥉</span>
                      <span v-else class="font-bold">{{ index + 1 }}</span>
                    </div>
                  </td>
                  <td>
                    <div class="flex items-center gap-3">
                      <div class="avatar placeholder">
                        <div 
                          class="rounded-full w-10"
                          :class="{
                            'bg-yellow-500 text-white': index === 0,
                            'bg-gray-400 text-white': index === 1,
                            'bg-orange-700 text-white': index === 2,
                            'bg-primary text-primary-content': userData && user.id === userData.id && index > 2,
                            'bg-neutral-focus text-neutral-content': !userData || user.id !== userData.id || index <= 2,
                          }"
                        >
                          <span class="text-sm">{{ user.username[0].toUpperCase() }}</span>
                        </div>
                      </div>
                      <div>
                        <div class="font-bold">
                          {{ user.username }}
                          <span v-if="userData && user.id === userData.id" class="badge badge-primary badge-sm ml-2">
                            Vous
                          </span>
                        </div>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div class="badge badge-lg badge-warning">
                      {{ user.tokens }} 🪙
                    </div>
                  </td>
                  <td>
                    <div class="flex items-center gap-2">
                      <span class="font-semibold">{{ (user.winrate * 100).toFixed(1) }}%</span>
                      <progress 
                        class="progress progress-success w-20" 
                        :value="user.winrate * 100" 
                        max="100"
                      ></progress>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Statistiques globales -->
          <div class="divider mt-6"></div>
          
          <div class="stats stats-vertical lg:stats-horizontal shadow w-full">
            <div class="stat">
              <div class="stat-title">Total Joueurs</div>
              <div class="stat-value text-primary">{{ rankedUsers.length }}</div>
              <div class="stat-desc">Utilisateurs actifs</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Tokens en Circulation</div>
              <div class="stat-value text-secondary">{{ totalTokens }}</div>
              <div class="stat-desc">Total des tokens</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Winrate Moyen</div>
              <div class="stat-value text-accent">{{ averageWinrate }}%</div>
              <div class="stat-desc">De tous les joueurs</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { UserData } from '~/types/database'

definePageMeta({
  middleware: 'auth',
})

const supabase = useSupabaseClient()
const { userData } = useUserData()
const { subscribe, unsubscribeAll } = useRealtime()

const rankedUsers = ref<UserData[]>([])
const loading = ref(true)

const userRank = computed(() => {
  if (!userData.value) return 0
  return rankedUsers.value.findIndex(u => u.id === userData.value!.id) + 1
})

const totalTokens = computed(() => {
  return rankedUsers.value.reduce((sum, user) => sum + user.tokens, 0)
})

const averageWinrate = computed(() => {
  if (rankedUsers.value.length === 0) return 0
  const sum = rankedUsers.value.reduce((sum, user) => sum + user.winrate, 0)
  return ((sum / rankedUsers.value.length) * 100).toFixed(1)
})

const loadLeaderboard = async () => {
  loading.value = true

  try {
    const { data, error } = await supabase
      .from('UserDatas')
      .select('*')
      .order('tokens', { ascending: false })

    if (error) throw error

    rankedUsers.value = data as UserData[]
  } catch (e) {
    console.error('Error loading leaderboard:', e)
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  await loadLeaderboard()

  // 📡 S'abonner aux changements en temps réel
  subscribe('UserDatas', async () => {
    console.log('🔄 Mise à jour temps réel du classement général')
    await loadLeaderboard()
  })
})

onUnmounted(() => {
  // 🔌 Se désabonner quand on quitte la page
  unsubscribeAll()
})
</script>


<template>
  <div class="container mx-auto px-4 py-8">
    <div v-if="loading" class="flex justify-center py-8">
      <span class="loading loading-spinner loading-lg"></span>
    </div>

    <div v-else-if="prono">
      <!-- En-tête du prono -->
      <div class="card bg-base-100 shadow-xl border border-red-900/30 mb-8">
        <div class="card-body">
          <div class="flex justify-between items-start">
            <div>
              <h1 class="text-3xl font-bold mb-2">{{ prono.name }}</h1>

              <div class="flex gap-2 mb-4">
                <div v-if="isActive" class="badge badge-success badge-lg">En cours</div>
                <div v-else-if="isPending" class="badge badge-warning badge-lg">À venir</div>
                <div v-else class="badge badge-error badge-lg">Terminé</div>
                
                <div v-if="hasResults" class="badge badge-neutral badge-lg">
                  🔒 Résultats définis
                </div>
                
                <div v-if="prono.team" class="badge badge-primary badge-lg">
                  🏆 {{ prono.team.name }}
                </div>
                <div v-else class="badge badge-info badge-lg">🌍 Public</div>
              </div>

              <div class="text-sm opacity-70 space-y-1">
                <p>📅 Début : {{ formatDate(prono.start_at) }}</p>
                <p>🏁 Fin : {{ formatDate(prono.end_at) }}</p>
                <p>👤 Créé par : {{ prono.owner?.username }}</p>
              </div>
            </div>

            <div v-if="availableTokens !== null" class="text-right">
              <p class="text-sm opacity-70">Tokens disponibles</p>
              <p class="text-3xl font-bold text-primary">{{ availableTokens }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Mes paris sur ce prono -->
      <div v-if="userBets.length > 0" class="card bg-base-100 shadow-xl border border-red-900/30 mb-8">
        <div class="card-body">
          <h2 class="card-title">Mes Paris</h2>

          <div class="space-y-2">
            <div
              v-for="userBet in userBets"
              :key="userBet.id"
              class="alert"
              :class="{
                'alert-success': userBet.bet?.result === true,
                'alert-error': userBet.bet?.result === false,
                'alert-info': userBet.bet?.result === null,
              }"
            >
              <div class="flex justify-between w-full">
                <div>
                  <p class="font-bold">{{ getBetTitle(userBet.bet_id) }}</p>
                  <p class="text-sm">Mise : {{ userBet.amount }} tokens</p>
                  <p class="text-sm">
                    Gain potentiel :
                    {{ calculateWin(userBet.amount, getBetOdds(userBet.bet_id)) }} tokens
                  </p>
                </div>

                <div class="text-right">
                  <p v-if="userBet.bet?.result === true" class="text-success font-bold">✓ Gagné</p>
                  <p v-else-if="userBet.bet?.result === false" class="text-error font-bold">
                    ✗ Perdu
                  </p>
                  <p v-else class="opacity-70">En attente</p>

                  <button
                    v-if="isPending && userBet.bet?.result === null"
                    class="btn btn-ghost btn-xs mt-2"
                    @click="handleDeleteBet(userBet.id)"
                  >
                    Annuler
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Options de pari -->
      <div class="mb-8">
        <h2 class="text-2xl font-bold mb-4">Options de Pari</h2>

        <div v-if="prono.team && !isMember" class="alert alert-error mb-4">
          <div>
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            <div>
              <span class="font-bold">Vous n'êtes pas membre de ce groupe</span>
              <p class="text-sm">Vous devez être membre du groupe "{{ prono.team.name }}" pour parier sur ce prono.</p>
              <NuxtLink :to="`/groups/${prono.team_id}`" class="btn btn-sm btn-primary mt-2">
                Rejoindre le groupe
              </NuxtLink>
            </div>
          </div>
        </div>

        <div v-if="!isActive && !isPending" class="alert alert-warning mb-4">
          <span>Ce pari est terminé, vous ne pouvez plus parier.</span>
        </div>
        
        <div v-if="hasResults" class="alert alert-info mb-4">
          <div>
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            <span>🔒 Les résultats ont été définis. Les paris sont fermés et les gains ont été distribués.</span>
          </div>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <BetOption 
            v-for="bet in prono.bets" 
            :key="bet.id" 
            :ref="(el: any) => betRefs[bet.id] = el"
            :bet="bet"
            :can-bet="isMember && (isActive || isPending) && !hasResults && availableTokens !== null && availableTokens > 0"
            :max-amount="availableTokens || 0"
            :stats="betStats[bet.id]"
            @place-bet="(amount: number) => handlePlaceBet(bet.id, amount)"
          >
            <template v-if="isOwner && !prono.bets.some((b: any) => b.result !== null)" #actions>
              <div class="divider">Actions propriétaire</div>
              <div class="flex gap-2">
                <button
                  class="btn btn-success btn-sm flex-1"
                  @click="handleSetResult(bet.id, true)"
                >
                  ✓ Gagnant
                </button>
                <button class="btn btn-error btn-sm flex-1" @click="handleSetResult(bet.id, false)">
                  ✗ Perdant
                </button>
              </div>
            </template>
          </BetOption>
        </div>
      </div>

      <!-- Statistiques -->
      <div class="card bg-base-100 shadow-xl border border-red-900/30">
        <div class="card-body">
          <h2 class="card-title">Statistiques</h2>

          <div class="stats stats-vertical lg:stats-horizontal shadow">
            <div class="stat">
              <div class="stat-title">Total des paris</div>
              <div class="stat-value text-primary">{{ totalBetsCount }}</div>
              <div class="stat-desc">Sur toutes les options</div>
            </div>

            <div class="stat">
              <div class="stat-title">Montant total</div>
              <div class="stat-value text-secondary">{{ totalAmount }}</div>
              <div class="stat-desc">Tokens misés</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div v-else class="alert alert-error">
      <span>Pari introuvable</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { PronoWithBets, BetUserData } from '~/types/database'

definePageMeta({
  middleware: 'auth',
})

const route = useRoute()
const pronoId = route.params.id as string

const { getPronoById } = usePronos()
const { placeBet, getUserBetsByProno, getBetStats, calculatePotentialWin, deleteBet } = useBets()
const { setResultAndDistribute } = useResults()
const { userData } = useUserData()
const { getUserTeamTokens, isTeamMember } = useTeams()
const { subscribeToPronoBets, unsubscribeAll } = useRealtime()

const prono = ref<PronoWithBets | null>(null)
const userBets = ref<BetUserData[]>([])
const betStats = ref<Record<string, { totalAmount: number; betCount: number }>>({})
const loading = ref(true)
const availableTokens = ref<number | null>(null)
const betRefs = ref<Record<string, any>>({})
const isMember = ref(true) // true by default for public bets

const isOwner = computed(() => {
  return userData.value && prono.value && userData.value.id === prono.value.owner_id
})

const now = new Date()
const startDate = computed(() => (prono.value ? new Date(prono.value.start_at) : null))
const endDate = computed(() => (prono.value ? new Date(prono.value.end_at) : null))

const isPending = computed(() => startDate.value && now < startDate.value)
const isActive = computed(
  () => startDate.value && endDate.value && now >= startDate.value && now <= endDate.value
)

const totalBetsCount = computed(() => {
  return Object.values(betStats.value).reduce((sum, stat) => sum + stat.betCount, 0)
})

const totalAmount = computed(() => {
  return Object.values(betStats.value).reduce((sum, stat) => sum + stat.totalAmount, 0)
})

const hasResults = computed(() => {
  return prono.value?.bets?.some(bet => bet.result !== null) || false
})

onMounted(async () => {
  await loadPronoData()
  await loadUserBets()
  await loadBetStats()
  await loadAvailableTokens()

  // 📡 S'abonner aux changements en temps réel
  subscribeToPronoBets(pronoId, async () => {
    console.log('🔄 Mise à jour temps réel du prono')
    await loadPronoData()
    await loadUserBets()
    await loadBetStats()
    await loadAvailableTokens()
  })
})

onUnmounted(() => {
  // 🔌 Se désabonner quand on quitte la page
  unsubscribeAll()
})

const loadPronoData = async () => {
  loading.value = true

  try {
    prono.value = await getPronoById(pronoId)
  } catch (e) {
    console.error('Error loading prono:', e)
  } finally {
    loading.value = false
  }
}

const loadUserBets = async () => {
  try {
    userBets.value = await getUserBetsByProno(pronoId)
  } catch (e) {
    console.error('Error loading user bets:', e)
  }
}

const loadBetStats = async () => {
  if (!prono.value?.bets) return

  for (const bet of prono.value.bets) {
    try {
      betStats.value[bet.id] = await getBetStats(bet.id)
    } catch (e) {
      console.error('Error loading bet stats:', e)
    }
  }
}

const loadAvailableTokens = async () => {
  if (!userData.value || !prono.value) return

  if (prono.value.team_id) {
    // Check if user is member of the group
    isMember.value = await isTeamMember(prono.value.team_id)
    if (isMember.value) {
      availableTokens.value = await getUserTeamTokens(prono.value.team_id)
    } else {
      availableTokens.value = 0
    }
  } else {
    // Public bet - everyone can bet
    isMember.value = true
    availableTokens.value = userData.value.tokens
  }
}

const handlePlaceBet = async (betId: string, amount: number) => {
  const betRef = betRefs.value[betId]
  if (betRef) betRef.setLoading(true)

  try {
    await placeBet(betId, amount, pronoId, prono.value?.team_id || null)

    if (betRef) betRef.resetAmount()

    await Promise.all([loadUserBets(), loadBetStats(), loadAvailableTokens()])
  } catch (e: any) {
    alert(e.message || 'Erreur lors du pari')
  } finally {
    if (betRef) betRef.setLoading(false)
  }
}

const handleSetResult = async (betId: string, result: boolean) => {
  if (!confirm(`Êtes-vous sûr de marquer cette option comme ${result ? 'gagnante' : 'perdante'} ? Les tokens seront distribués automatiquement aux gagnants.`)) return
  
  try {
    await setResultAndDistribute(betId, result)
    await loadPronoData()
    await loadBetStats()
  } catch (e: any) {
    alert(e.message || 'Erreur lors de la mise à jour')
  }
}

const handleDeleteBet = async (betUserDataId: string) => {
  if (!confirm('Êtes-vous sûr de vouloir annuler ce pari ?')) return

  try {
    await deleteBet(betUserDataId)
    await Promise.all([loadUserBets(), loadBetStats(), loadAvailableTokens()])
  } catch (e: any) {
    alert(e.message || "Erreur lors de l'annulation")
  }
}

const getBetTitle = (betId: string) => {
  return prono.value?.bets?.find((b) => b.id === betId)?.title || ''
}

const getBetOdds = (betId: string) => {
  return prono.value?.bets?.find((b) => b.id === betId)?.odds || 1
}

const calculateWin = (amount: number, odds: number) => {
  return calculatePotentialWin(amount, odds)
}

const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}
</script>

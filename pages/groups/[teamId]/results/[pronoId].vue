<template>
  <div class="container mx-auto px-4 py-8">
    <div class="max-w-4xl mx-auto">
      <div class="flex items-center gap-4 mb-8">
        <NuxtLink :to="`/groups/${teamId}`" class="btn btn-ghost btn-circle">
          ← 
        </NuxtLink>
        <div>
          <h1 class="text-3xl font-bold bg-gradient-to-r from-red-600 to-red-500 bg-clip-text text-transparent">
            Définir les Résultats
          </h1>
          <p class="text-sm opacity-70 mt-1">{{ prono?.name }}</p>
        </div>
      </div>

      <div v-if="loading" class="flex justify-center py-8">
        <span class="loading loading-spinner loading-lg"></span>
      </div>

      <div v-else-if="prono" class="space-y-6">
        <!-- Informations du pari -->
        <div class="card bg-base-100 shadow-xl border border-red-900/30">
          <div class="card-body">
            <h2 class="card-title">Informations</h2>
            <div class="text-sm space-y-1">
              <p>📅 Début : {{ formatDate(prono.start_at) }}</p>
              <p>🏁 Fin : {{ formatDate(prono.end_at) }}</p>
              <p>🎯 Options : {{ prono.bets?.length || 0 }}</p>
              <p>👥 Groupe : {{ prono.team?.name }}</p>
            </div>
          </div>
        </div>

        <!-- Options de pari -->
        <div class="card bg-base-100 shadow-xl border border-red-900/30">
          <div class="card-body">
            <h2 class="card-title mb-4">Définir le(s) gagnant(s)</h2>
            
            <div class="alert alert-warning mb-4">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>
              <span>⚠️ Cette action est définitive. Les tokens seront distribués aux gagnants du groupe.</span>
            </div>

            <div class="space-y-3">
              <div 
                v-for="bet in prono.bets" 
                :key="bet.id"
                class="card bg-base-200 border-2"
                :class="{
                  'border-green-500': results[bet.id] === true,
                  'border-red-500': results[bet.id] === false,
                  'border-base-300': results[bet.id] === null
                }"
              >
                <div class="card-body p-4">
                  <div class="flex justify-between items-center">
                    <div class="flex-1">
                      <h3 class="font-bold text-lg">{{ bet.title }}</h3>
                      <p class="text-sm opacity-70">Cote : {{ bet.odds }}x</p>
                      <p v-if="betStats[bet.id]" class="text-sm mt-1">
                        💰 {{ betStats[bet.id].totalAmount }} tokens misés par {{ betStats[bet.id].betCount }} membre(s)
                      </p>
                    </div>
                    
                    <div class="flex gap-2">
                      <button 
                        @click="setResult(bet.id, true)" 
                        class="btn btn-sm"
                        :class="results[bet.id] === true ? 'btn-success' : 'btn-outline btn-success'"
                        :disabled="saving"
                      >
                        ✓ Gagné
                      </button>
                      <button 
                        @click="setResult(bet.id, false)" 
                        class="btn btn-sm"
                        :class="results[bet.id] === false ? 'btn-error' : 'btn-outline btn-error'"
                        :disabled="saving"
                      >
                        ✗ Perdu
                      </button>
                      <button 
                        v-if="results[bet.id] !== null"
                        @click="setResult(bet.id, null)" 
                        class="btn btn-ghost btn-sm"
                        :disabled="saving"
                      >
                        ↺
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div v-if="error" class="alert alert-error mt-4">
              <span>{{ error }}</span>
            </div>

            <div v-if="success" class="alert alert-success mt-4">
              <span>{{ success }}</span>
            </div>

            <div class="card-actions justify-end mt-6">
              <NuxtLink :to="`/groups/${teamId}`" class="btn btn-ghost">
                Annuler
              </NuxtLink>
              <button 
                @click="handleSaveResults" 
                class="btn btn-primary"
                :disabled="!hasResults || saving"
              >
                <span v-if="saving" class="loading loading-spinner"></span>
                {{ saving ? 'Enregistrement...' : '💾 Enregistrer les résultats' }}
              </button>
            </div>
          </div>
        </div>
      </div>

      <div v-else class="alert alert-error">
        <span>Pari introuvable</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { PronoWithBets } from '~/types/database'

definePageMeta({
  middleware: 'auth',
})

const route = useRoute()
const teamId = route.params.teamId as string
const pronoId = route.params.pronoId as string

const { getPronoById } = usePronos()
const { getBetStats } = useBets()
const { setResultAndDistribute } = useResults()

const prono = ref<PronoWithBets | null>(null)
const results = ref<Record<string, boolean | null>>({})
const betStats = ref<Record<string, { totalAmount: number; betCount: number }>>({})
const loading = ref(true)
const saving = ref(false)
const error = ref('')
const success = ref('')

const hasResults = computed(() => {
  return Object.values(results.value).some(r => r !== null)
})

onMounted(async () => {
  await loadProno()
})

const loadProno = async () => {
  loading.value = true
  
  try {
    prono.value = await getPronoById(pronoId)
    
    // Vérifier que c'est bien un prono du groupe
    if (prono.value.team_id !== teamId) {
      throw new Error('Ce pari n\'appartient pas à ce groupe')
    }
    
    // Initialiser les résultats
    if (prono.value?.bets) {
      for (const bet of prono.value.bets) {
        results.value[bet.id] = bet.result
        
        // Charger les stats
        try {
          betStats.value[bet.id] = await getBetStats(bet.id)
        } catch (e) {
          console.error('Error loading bet stats:', e)
        }
      }
    }
  } catch (e) {
    console.error('Error loading prono:', e)
  } finally {
    loading.value = false
  }
}

const setResult = (betId: string, result: boolean | null) => {
  results.value[betId] = result
}

const handleSaveResults = async () => {
  if (!confirm('Êtes-vous sûr ? Les tokens seront distribués automatiquement aux gagnants.')) return
  
  saving.value = true
  error.value = ''
  success.value = ''
  
  try {
    // Mettre à jour tous les résultats ET distribuer les gains
    for (const [betId, result] of Object.entries(results.value)) {
      if (result !== null) {
        await setResultAndDistribute(betId, result)
      }
    }
    
    success.value = '✅ Résultats enregistrés et gains distribués avec succès ! Redirection...'
    
    setTimeout(() => {
      navigateTo(`/groups/${teamId}`)
    }, 2000)
  } catch (e: any) {
    error.value = e.message || 'Erreur lors de l\'enregistrement'
    console.error('Erreur détaillée:', e)
  } finally {
    saving.value = false
  }
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


<template>
  <div class="container mx-auto px-4 py-8">
    <div class="flex justify-between items-center mb-8">
      <div>
        <h1 class="text-3xl font-bold bg-gradient-to-r from-red-600 to-red-500 bg-clip-text text-transparent">
          Dashboard Admin
        </h1>
        <p class="text-sm opacity-70 mt-2">Gestion des paris publics</p>
      </div>
      <NuxtLink to="/admin/create-prono" class="btn btn-primary">
        ➕ Créer un pari public
      </NuxtLink>
    </div>

    <!-- Statistiques -->
    <div class="stats stats-vertical lg:stats-horizontal shadow w-full mb-8">
      <div class="stat">
        <div class="stat-title">Paris publics actifs</div>
        <div class="stat-value text-primary">{{ activePronos.length }}</div>
        <div class="stat-desc">En cours ou à venir</div>
      </div>
      
      <div class="stat">
        <div class="stat-title">Paris terminés</div>
        <div class="stat-value text-secondary">{{ completedPronos.length }}</div>
        <div class="stat-desc">Résultats définis</div>
      </div>
      
      <div class="stat">
        <div class="stat-title">Total utilisateurs</div>
        <div class="stat-value text-accent">{{ totalUsers }}</div>
        <div class="stat-desc">Inscrits sur la plateforme</div>
      </div>
    </div>

    <!-- Onglets -->
    <div class="tabs tabs-boxed mb-6">
      <a 
        class="tab" 
        :class="{ 'tab-active': activeTab === 'active' }"
        @click="activeTab = 'active'"
      >
        🎯 Paris Actifs
      </a>
      <a 
        class="tab" 
        :class="{ 'tab-active': activeTab === 'completed' }"
        @click="activeTab = 'completed'"
      >
        ✅ Paris Terminés
      </a>
      <a 
        class="tab" 
        :class="{ 'tab-active': activeTab === 'all' }"
        @click="activeTab = 'all'"
      >
        📋 Tous les Paris
      </a>
    </div>

    <!-- Liste des pronos -->
    <div v-if="loading" class="flex justify-center py-8">
      <span class="loading loading-spinner loading-lg"></span>
    </div>

    <div v-else class="space-y-4">
      <div 
        v-for="prono in filteredPronos" 
        :key="prono.id"
        class="card bg-base-100 shadow-xl border border-red-900/30 hover:border-red-600/50"
      >
        <div class="card-body">
          <div class="flex justify-between items-start">
            <div class="flex-1">
              <h3 class="card-title text-xl mb-2">{{ prono.name }}</h3>
              
              <div class="flex gap-2 mb-3">
                <div v-if="isActive(prono)" class="badge badge-success">En cours</div>
                <div v-else-if="isPending(prono)" class="badge badge-warning">À venir</div>
                <div v-else class="badge badge-error">Terminé</div>
                <div class="badge badge-info">Public</div>
              </div>
              
              <div class="text-sm space-y-1 opacity-70">
                <p>📅 Début : {{ formatDate(prono.start_at) }}</p>
                <p>🏁 Fin : {{ formatDate(prono.end_at) }}</p>
                <p>🎯 Options : {{ prono.bets?.length || 0 }}</p>
              </div>
            </div>
            
            <div class="flex gap-2">
              <NuxtLink 
                :to="`/pronos/${prono.id}`" 
                class="btn btn-ghost btn-sm"
              >
                👁️ Voir
              </NuxtLink>
              <NuxtLink 
                v-if="!isActive(prono) && !isPending(prono)"
                :to="`/admin/results/${prono.id}`" 
                class="btn btn-success btn-sm"
              >
                🏆 Résultats
              </NuxtLink>
              <button 
                @click="handleDelete(prono.id)" 
                class="btn btn-error btn-sm"
                :disabled="deleting === prono.id"
              >
                <span v-if="deleting === prono.id" class="loading loading-spinner loading-xs"></span>
                {{ deleting === prono.id ? '' : '🗑️' }}
              </button>
            </div>
          </div>
        </div>
      </div>

      <div v-if="filteredPronos.length === 0" class="alert alert-info">
        <span>Aucun pari trouvé dans cette catégorie.</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { PronoWithBets } from '~/types/database'

definePageMeta({
  middleware: 'auth',
})

const { getPublicPronos, deleteProno } = usePronos()
const supabase = useSupabaseClient()

const pronos = ref<PronoWithBets[]>([])
const loading = ref(true)
const activeTab = ref<'active' | 'completed' | 'all'>('active')
const deleting = ref<string | null>(null)
const totalUsers = ref(0)

const now = new Date()

const activePronos = computed(() => {
  return pronos.value.filter(p => {
    const start = new Date(p.start_at)
    const end = new Date(p.end_at)
    return now >= start && now <= end
  })
})

const completedPronos = computed(() => {
  return pronos.value.filter(p => {
    const end = new Date(p.end_at)
    return now > end
  })
})

const pendingPronos = computed(() => {
  return pronos.value.filter(p => {
    const start = new Date(p.start_at)
    return now < start
  })
})

const filteredPronos = computed(() => {
  if (activeTab.value === 'active') {
    return [...activePronos.value, ...pendingPronos.value]
  } else if (activeTab.value === 'completed') {
    return completedPronos.value
  }
  return pronos.value
})

const isPending = (prono: PronoWithBets) => {
  const start = new Date(prono.start_at)
  return now < start
}

const isActive = (prono: PronoWithBets) => {
  const start = new Date(prono.start_at)
  const end = new Date(prono.end_at)
  return now >= start && now <= end
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

onMounted(async () => {
  await loadData()
})

const loadData = async () => {
  loading.value = true
  
  try {
    pronos.value = await getPublicPronos()
    
    // Compter les utilisateurs
    const { count } = await supabase
      .from('UserDatas')
      .select('*', { count: 'exact', head: true })
    
    totalUsers.value = count || 0
  } catch (e) {
    console.error('Error loading data:', e)
  } finally {
    loading.value = false
  }
}

const handleDelete = async (pronoId: string) => {
  if (!confirm('Êtes-vous sûr de vouloir supprimer ce pari ? Cette action est irréversible.')) return
  
  deleting.value = pronoId
  
  try {
    await deleteProno(pronoId)
    await loadData()
  } catch (e: any) {
    alert(e.message || 'Erreur lors de la suppression')
  } finally {
    deleting.value = null
  }
}
</script>


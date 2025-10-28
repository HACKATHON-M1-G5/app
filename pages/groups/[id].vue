<template>
  <div class="container mx-auto px-4 py-8">
    <div v-if="loading" class="flex justify-center py-8">
      <span class="loading loading-spinner loading-lg"></span>
    </div>
    
    <div v-else-if="team">
      <!-- En-tête du groupe -->
      <div class="card bg-base-100 shadow-xl mb-8">
        <div class="card-body">
          <div class="flex items-start gap-6">
            <div 
              class="avatar placeholder"
              :style="{ backgroundColor: team.primary_color }"
            >
              <div class="w-24 rounded-xl text-white">
                <span v-if="!team.icon_url" class="text-4xl">{{ team.name[0] }}</span>
                <img v-else :src="team.icon_url" :alt="team.name" />
              </div>
            </div>
            
            <div class="flex-1">
              <div class="flex items-center gap-3 mb-2">
                <h1 class="text-3xl font-bold">{{ team.name }}</h1>
                <div class="badge badge-lg" :class="team.privacy ? 'badge-secondary' : 'badge-success'">
                  {{ team.privacy ? 'Privé' : 'Public' }}
                </div>
              </div>
              
              <p class="text-lg opacity-70 mb-4">{{ team.description }}</p>
              
              <div class="flex gap-4 items-center">
                <div class="badge badge-outline badge-lg">
                  👥 {{ members.length }} membre{{ members.length > 1 ? 's' : '' }}
                </div>
                <div v-if="userMembership" class="badge badge-primary badge-lg">
                  💰 {{ userMembership.token }} tokens
                </div>
              </div>
              
              <div v-if="team.privacy && isOwner" class="mt-4">
                <div class="alert alert-info">
                  <div>
                    <span class="font-bold">Code d'invitation :</span>
                    <code class="ml-2 px-2 py-1 bg-base-200 rounded">{{ team.join_code }}</code>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <div class="card-actions justify-end mt-4">
            <button 
              v-if="!isMember && !isOwner"
              @click="handleJoinTeam" 
              class="btn btn-primary"
              :disabled="joining"
            >
              <span v-if="joining" class="loading loading-spinner"></span>
              {{ joining ? 'Inscription...' : 'Rejoindre le groupe' }}
            </button>
            
            <button 
              v-if="isMember && !isOwner"
              @click="handleLeaveTeam" 
              class="btn btn-error"
              :disabled="leaving"
            >
              <span v-if="leaving" class="loading loading-spinner"></span>
              {{ leaving ? 'Sortie...' : 'Quitter le groupe' }}
            </button>
            
            <NuxtLink 
              v-if="isOwner"
              :to="`/groups/${team.id}/create-prono`" 
              class="btn btn-primary"
            >
              ➕ Créer un pari
            </NuxtLink>
          </div>
        </div>
      </div>

      <!-- Onglets -->
      <div class="tabs tabs-boxed mb-6">
        <a 
          class="tab" 
          :class="{ 'tab-active': activeTab === 'pronos' }"
          @click="activeTab = 'pronos'"
        >
          🎯 Paris
        </a>
        <a 
          class="tab" 
          :class="{ 'tab-active': activeTab === 'members' }"
          @click="activeTab = 'members'"
        >
          👥 Membres
        </a>
      </div>

      <!-- Contenu des onglets -->
      <div v-if="activeTab === 'pronos'">
        <div v-if="loadingPronos" class="flex justify-center py-8">
          <span class="loading loading-spinner loading-lg"></span>
        </div>
        
        <div v-else-if="pronos.length === 0" class="alert alert-info">
          <span>Aucun pari pour ce groupe. {{ isOwner ? 'Créez-en un !' : '' }}</span>
        </div>
        
        <div v-else class="grid grid-cols-1 gap-4">
          <div 
            v-for="prono in pronos" 
            :key="prono.id"
            class="card bg-base-100 shadow-xl border border-red-900/30 hover:border-red-600/50"
          >
            <div class="card-body">
              <div class="flex justify-between items-start">
                <div class="flex-1">
                  <h3 class="card-title text-xl mb-2">
                    {{ prono.name }}
                    <div v-if="isPronoActive(prono)" class="badge badge-success">En cours</div>
                    <div v-else-if="isPronoPending(prono)" class="badge badge-warning">À venir</div>
                    <div v-else class="badge badge-error">Terminé</div>
                  </h3>
                  
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
                    v-if="isOwner && !isPronoActive(prono) && !isPronoPending(prono)"
                    :to="`/groups/${team.id}/results/${prono.id}`" 
                    class="btn btn-success btn-sm"
                  >
                    🏆 Résultats
                  </NuxtLink>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div v-if="activeTab === 'members'">
        <div class="grid grid-cols-1 gap-4">
          <div 
            v-for="member in members" 
            :key="member.id" 
            class="card bg-base-100 shadow-xl"
          >
            <div class="card-body">
              <div class="flex justify-between items-center">
                <div class="flex items-center gap-4">
                  <div class="avatar placeholder">
                    <div class="bg-neutral-focus text-neutral-content rounded-full w-12">
                      <span class="text-xl">{{ member.userdata.username[0].toUpperCase() }}</span>
                    </div>
                  </div>
                  
                  <div>
                    <h3 class="font-bold">{{ member.userdata.username }}</h3>
                    <div class="flex gap-2 mt-1">
                      <div 
                        class="badge" 
                        :class="{
                          'badge-primary': member.status === 'owner',
                          'badge-success': member.status === 'member',
                          'badge-warning': member.status === 'pending',
                          'badge-error': member.status === 'banned'
                        }"
                      >
                        {{ statusLabel(member.status) }}
                      </div>
                      <div class="badge badge-outline">💰 {{ member.token }} tokens</div>
                    </div>
                  </div>
                </div>
                
                <div v-if="isOwner && member.status !== 'owner'" class="flex gap-2">
                  <button 
                    v-if="member.status === 'pending'"
                    @click="handleUpdateStatus(member.userdata_id, 'member')" 
                    class="btn btn-success btn-sm"
                  >
                    ✓ Accepter
                  </button>
                  
                  <button 
                    v-if="member.status === 'pending'"
                    @click="handleUpdateStatus(member.userdata_id, 'banned')" 
                    class="btn btn-error btn-sm"
                  >
                    ✗ Refuser
                  </button>
                  
                  <button 
                    v-if="member.status === 'member'"
                    @click="handleUpdateStatus(member.userdata_id, 'banned')" 
                    class="btn btn-error btn-sm"
                  >
                    🚫 Bannir
                  </button>
                  
                  <button 
                    v-if="member.status === 'banned'"
                    @click="handleUpdateStatus(member.userdata_id, 'member')" 
                    class="btn btn-success btn-sm"
                  >
                    ↩️ Débannir
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div v-else class="alert alert-error">
      <span>Groupe introuvable</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Team, TeamUserData, PronoWithBets } from '~/types/database'

definePageMeta({
  middleware: 'auth',
})

const route = useRoute()
const teamId = route.params.id as string

const { 
  getTeamById, 
  getTeamMembers, 
  joinTeam, 
  leaveTeam, 
  isTeamOwner,
  updateMemberStatus 
} = useTeams()
const { getTeamPronos } = usePronos()
const { userData } = useUserData()

const team = ref<Team | null>(null)
const members = ref<(TeamUserData & { userdata: any })[]>([])
const pronos = ref<PronoWithBets[]>([])
const loading = ref(true)
const loadingPronos = ref(false)
const joining = ref(false)
const leaving = ref(false)
const activeTab = ref<'pronos' | 'members'>('pronos')

const isOwner = ref(false)

const userMembership = computed(() => {
  if (!userData.value) return null
  return members.value.find(m => m.userdata_id === userData.value!.id)
})

const isMember = computed(() => {
  return userMembership.value?.status === 'member'
})

onMounted(async () => {
  await loadTeamData()
  await loadPronos()
})

const loadTeamData = async () => {
  loading.value = true
  
  try {
    team.value = await getTeamById(teamId)
    members.value = await getTeamMembers(teamId)
    isOwner.value = await isTeamOwner(teamId)
  } catch (e) {
    console.error('Error loading team:', e)
  } finally {
    loading.value = false
  }
}

const loadPronos = async () => {
  loadingPronos.value = true
  
  try {
    pronos.value = await getTeamPronos(teamId)
  } catch (e) {
    console.error('Error loading pronos:', e)
  } finally {
    loadingPronos.value = false
  }
}

const handleJoinTeam = async () => {
  joining.value = true
  
  try {
    await joinTeam(teamId)
    await loadTeamData()
  } catch (e: any) {
    alert(e.message || 'Erreur lors de l\'inscription')
  } finally {
    joining.value = false
  }
}

const handleLeaveTeam = async () => {
  if (!confirm('Êtes-vous sûr de vouloir quitter ce groupe ?')) return
  
  leaving.value = true
  
  try {
    await leaveTeam(teamId)
    await navigateTo('/groups')
  } catch (e: any) {
    alert(e.message || 'Erreur lors de la sortie du groupe')
  } finally {
    leaving.value = false
  }
}

const handleUpdateStatus = async (userId: string, status: 'pending' | 'member' | 'banned' | 'owner') => {
  try {
    await updateMemberStatus(teamId, userId, status)
    await loadTeamData()
  } catch (e: any) {
    alert(e.message || 'Erreur lors de la mise à jour')
  }
}

const statusLabel = (status: string) => {
  const labels: Record<string, string> = {
    owner: '👑 Propriétaire',
    member: '✓ Membre',
    pending: '⏳ En attente',
    banned: '🚫 Banni'
  }
  return labels[status] || status
}

const isPronoPending = (prono: PronoWithBets) => {
  const now = new Date()
  const start = new Date(prono.start_at)
  return now < start
}

const isPronoActive = (prono: PronoWithBets) => {
  const now = new Date()
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
</script>


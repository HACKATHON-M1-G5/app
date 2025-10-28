<template>
  <div class="container mx-auto px-4 py-8">
    <div class="max-w-2xl mx-auto">
      <div v-if="loading" class="flex justify-center py-8">
        <span class="loading loading-spinner loading-lg"></span>
      </div>

      <div v-else-if="team" class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h1 class="text-3xl font-bold mb-4">Invitation à rejoindre un groupe</h1>

          <div class="flex items-start gap-6 mb-6">
            <div class="avatar placeholder" :style="{ backgroundColor: team.primary_color }">
              <div class="w-20 rounded-xl text-white">
                <span v-if="!team.icon_url" class="text-3xl">{{ team.name[0] }}</span>
                <img v-else :src="team.icon_url" :alt="team.name" />
              </div>
            </div>

            <div>
              <h2 class="text-2xl font-bold">{{ team.name }}</h2>
              <p class="text-lg opacity-70 mt-2">{{ team.description }}</p>

              <div class="flex gap-2 mt-3">
                <div v-if="team.privacy" class="badge badge-secondary badge-lg">Privé</div>
                <div v-else class="badge badge-success badge-lg">Public</div>
              </div>
            </div>
          </div>

          <div v-if="error" class="alert alert-error mb-4">
            <span>{{ error }}</span>
          </div>

          <div v-if="alreadyMember" class="alert alert-info mb-4">
            <span>Vous êtes déjà membre de ce groupe !</span>
          </div>

          <div class="card-actions justify-end">
            <NuxtLink to="/groups" class="btn btn-ghost"> Retour aux groupes </NuxtLink>

            <button
              v-if="!alreadyMember"
              class="btn btn-primary"
              :disabled="joining"
              @click="handleJoinTeam"
            >
              <span v-if="joining" class="loading loading-spinner"></span>
              {{ joining ? 'Inscription...' : 'Rejoindre ce groupe' }}
            </button>

            <NuxtLink v-else :to="`/groups/${team.id}`" class="btn btn-primary">
              Voir le groupe
            </NuxtLink>
          </div>
        </div>
      </div>

      <div v-else class="alert alert-error">
        <span>Code d'invitation invalide ou groupe introuvable</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Team } from '~/types/database'

definePageMeta({
  middleware: 'auth',
})

const route = useRoute()
const joinCode = route.params.code as string

const { getTeamByJoinCode, joinTeam, getMyTeams } = useTeams()

const team = ref<Team | null>(null)
const loading = ref(true)
const joining = ref(false)
const error = ref('')
const alreadyMember = ref(false)

onMounted(async () => {
  await loadTeam()
})

const loadTeam = async () => {
  loading.value = true

  try {
    team.value = await getTeamByJoinCode(joinCode)

    // Vérifier si l'utilisateur est déjà membre
    const myTeams = await getMyTeams()
    alreadyMember.value = myTeams.some((t) => t.id === team.value?.id)
  } catch (e: any) {
    error.value = e.message || 'Code invalide'
    team.value = null
  } finally {
    loading.value = false
  }
}

const handleJoinTeam = async () => {
  if (!team.value) return

  joining.value = true
  error.value = ''

  try {
    await joinTeam(team.value.id, joinCode)
    await navigateTo(`/groups/${team.value.id}`)
  } catch (e: any) {
    error.value = e.message || "Erreur lors de l'inscription"
  } finally {
    joining.value = false
  }
}
</script>

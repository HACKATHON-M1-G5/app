<template>
  <div class="container mx-auto px-4 py-8">
    <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-3 sm:gap-0 mb-8">
      <h1 class="text-2xl md:text-3xl font-bold">Groupes</h1>
      <NuxtLink
        to="/groups/create"
        class="btn btn-primary btn-sm md:btn-md self-start sm:self-auto"
      >
        ➕ Créer un groupe
      </NuxtLink>
    </div>

    <!-- Mes Groupes -->
    <section class="mb-12">
      <h2 class="text-xl md:text-2xl font-bold mb-4">Mes Groupes</h2>

      <div v-if="loadingMyTeams" class="flex justify-center py-8">
        <span class="loading loading-spinner loading-lg"></span>
      </div>

      <div v-else-if="myTeams.length === 0" class="alert alert-info">
        <span>Vous n'êtes membre d'aucun groupe. Créez-en un ou rejoignez un groupe public !</span>
      </div>

      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <GroupCard v-for="team in myTeams" :key="team.id" :team="team" />
      </div>
    </section>

    <!-- Groupes Publics -->
    <section>
      <h2 class="text-xl md:text-2xl font-bold mb-4">Groupes Publics</h2>

      <div v-if="loadingPublicTeams" class="flex justify-center py-8">
        <span class="loading loading-spinner loading-lg"></span>
      </div>

      <div v-else-if="publicTeams.length === 0" class="alert alert-info">
        <span>Aucun groupe public disponible pour le moment.</span>
      </div>

      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <GroupCard v-for="team in publicTeams" :key="team.id" :team="team">
          <template #actions>
            <NuxtLink :to="`/groups/${team.id}`" class="btn btn-ghost btn-xs sm:btn-sm">
              Voir
            </NuxtLink>
            <button
              v-if="!isMyTeam(team.id)"
              class="btn btn-primary btn-xs sm:btn-sm"
              :disabled="joiningTeamId === team.id"
              @click="handleJoinTeam(team.id)"
            >
              <span
                v-if="joiningTeamId === team.id"
                class="loading loading-spinner loading-xs"
              ></span>
              {{ joiningTeamId === team.id ? 'Inscription...' : 'Rejoindre' }}
            </button>
            <span v-else class="badge badge-success">Membre</span>
          </template>
        </GroupCard>
      </div>
    </section>

    <!-- Modal pour code d'invitation -->
    <div class="mt-8 text-center">
      <button class="btn btn-outline" @click="showJoinModal = true">
        🔑 Rejoindre avec un code
      </button>
    </div>

    <dialog :open="showJoinModal" class="modal" @click.self="showJoinModal = false">
      <div class="modal-box">
        <h3 class="font-bold text-lg mb-4">Rejoindre un groupe privé</h3>

        <div class="form-control">
          <label class="label">
            <span class="label-text">Code d'invitation</span>
          </label>
          <input
            v-model="joinCode"
            type="text"
            placeholder="ABC12345"
            class="input input-bordered uppercase"
            @input="joinCode = joinCode.toUpperCase()"
          />
        </div>

        <div v-if="joinError" class="alert alert-error mt-4">
          <span>{{ joinError }}</span>
        </div>

        <div class="modal-action">
          <button class="btn btn-ghost" @click="showJoinModal = false">Annuler</button>
          <button
            class="btn btn-primary"
            :disabled="!joinCode || joiningWithCode"
            @click="handleJoinWithCode"
          >
            <span v-if="joiningWithCode" class="loading loading-spinner"></span>
            {{ joiningWithCode ? 'Inscription...' : 'Rejoindre' }}
          </button>
        </div>
      </div>
    </dialog>
  </div>
</template>

<script setup lang="ts">
import type { Team } from '~/types/database'

definePageMeta({
  middleware: 'auth',
})

const { getMyTeams, getPublicTeams, joinTeam, getTeamByJoinCode } = useTeams()

const myTeams = ref<Team[]>([])
const publicTeams = ref<Team[]>([])
const loadingMyTeams = ref(true)
const loadingPublicTeams = ref(true)
const joiningTeamId = ref<string | null>(null)

const showJoinModal = ref(false)
const joinCode = ref('')
const joiningWithCode = ref(false)
const joinError = ref('')

onMounted(async () => {
  await Promise.all([loadMyTeams(), loadPublicTeams()])
})

const loadMyTeams = async () => {
  loadingMyTeams.value = true
  try {
    myTeams.value = await getMyTeams()
  } catch (e) {
    console.error('Error loading my teams:', e)
  } finally {
    loadingMyTeams.value = false
  }
}

const loadPublicTeams = async () => {
  loadingPublicTeams.value = true
  try {
    publicTeams.value = await getPublicTeams()
  } catch (e) {
    console.error('Error loading public teams:', e)
  } finally {
    loadingPublicTeams.value = false
  }
}

const isMyTeam = (teamId: string) => {
  return myTeams.value.some((team) => team.id === teamId)
}

const handleJoinTeam = async (teamId: string) => {
  joiningTeamId.value = teamId

  try {
    await joinTeam(teamId)
    await loadMyTeams()
  } catch (e: any) {
    alert(e.message || "Erreur lors de l'inscription au groupe")
  } finally {
    joiningTeamId.value = null
  }
}

const handleJoinWithCode = async () => {
  if (!joinCode.value) return

  joiningWithCode.value = true
  joinError.value = ''

  try {
    const team = await getTeamByJoinCode(joinCode.value)
    await joinTeam(team.id, joinCode.value)
    await loadMyTeams()

    showJoinModal.value = false
    joinCode.value = ''

    navigateTo(`/groups/${team.id}`)
  } catch (e: any) {
    joinError.value = e.message || "Code invalide ou erreur lors de l'inscription"
  } finally {
    joiningWithCode.value = false
  }
}
</script>

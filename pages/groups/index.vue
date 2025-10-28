<template>
  <div class="container mx-auto px-4 py-8">
    <!-- Header -->
    <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between mb-6">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Groupes</h1>
        <p class="text-sm text-base-content/60 mt-1">Gérez vos groupes, rejoignez-en de nouveaux, ou créez-en un en un clic.</p>
      </div>
      <div class="flex items-center gap-2">
        <NuxtLink to="/groups/create" class="btn btn-primary gap-2">
          <span aria-hidden>➕</span>
          <span>Créer un groupe</span>
        </NuxtLink>
        <button @click="openJoinModal" class="btn btn-outline gap-2">
          <span aria-hidden>🔑</span>
          <span>Rejoindre</span>
        </button>
      </div>
    </div>

    <!-- Tabs + search -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-3 mb-6">
      <div class="tabs tabs-boxed">
        <button
            class="tab h-auto"
            :class="{ 'tab-active': activeTab === 'mine' }"
            @click="activeTab = 'mine'"
        >
          Mes Groupes
        </button>
        <button
            class="tab h-auto"
            :class="{ 'tab-active': activeTab === 'public' }"
            @click="activeTab = 'public'"
        >
          Groupes Publics
        </button>
      </div>

      <div v-if="activeTab === 'public'" class="w-full md:w-80">
        <label class="input input-bordered flex items-center gap-2">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5 opacity-60"><path fill-rule="evenodd" d="M10.5 3.75a6.75 6.75 0 1 0 4.2 12.06l3.22 3.22a.75.75 0 1 0 1.06-1.06l-3.22-3.22a6.75 6.75 0 0 0-5.06-11zM5.25 10.5a5.25 5.25 0 1 1 10.5 0 5.25 5.25 0 0 1-10.5 0z" clip-rule="evenodd"/></svg>
          <input v-model.trim="publicSearch" type="search" placeholder="Rechercher un groupe public…" class="grow" @keyup.enter="reloadPublic()"/>
          <button class="btn btn-ghost btn-sm" @click="clearSearch" v-if="publicSearch">Effacer</button>
        </label>
      </div>
    </div>

    <!-- Content -->
    <section v-show="activeTab === 'mine'">
      <h2 class="sr-only">Mes Groupes</h2>
      <div v-if="myTeams.length === 0" class="alert">
        <div class="flex items-start gap-3">
          <span class="text-2xl" aria-hidden>🫥</span>
          <div>
            <h3 class="font-semibold">Aucun groupe pour l’instant</h3>
            <p class="text-base-content/70">Créez votre premier groupe ou rejoignez un groupe public ci‑dessous.</p>
          </div>
        </div>
      </div>
      <!-- List -->
      <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        <GroupCard v-for="team in myTeams" :key="team.id" :team="team" />
      </div>
    </section>

    <section v-show="activeTab === 'public'">
      <h2 class="sr-only">Groupes Publics</h2>
      <!-- Empty -->
      <div v-if="publicTeams.length === 0" class="alert">
        <div class="flex items-start gap-3">
          <span class="text-2xl" aria-hidden>🪹</span>
          <div>
            <h3 class="font-semibold">Aucun groupe public disponible</h3>
            <p class="text-base-content/70">Réessayez plus tard ou créez votre propre groupe.</p>
          </div>
        </div>
      </div>
      <!-- List -->
      <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        <GroupCard
            v-for="team in filteredPublic"
            :key="team.id"
            :team="team"
        >
          <template #actions>
            <NuxtLink :to="`/groups/${team.id}`" class="btn btn-ghost btn-sm">Voir</NuxtLink>

            <button
                v-if="!isMyTeam(team.id)"
                @click="handleJoinTeam(team.id)"
                class="btn btn-primary btn-sm"
                :disabled="joiningTeamId === team.id"
            >
              <span v-if="joiningTeamId === team.id" class="loading loading-spinner loading-xs" aria-hidden></span>
              <span>{{ joiningTeamId === team.id ? 'Inscription…' : 'Rejoindre' }}</span>
            </button>

            <span v-else class="badge badge-success">Membre</span>
          </template>
        </GroupCard>
      </div>
    </section>

    <!-- Join Modal -->
    <dialog
        ref="joinDialog"
        :open="showJoinModal"
        class="modal"
        @click.self="closeJoinModal"
    >
      <div class="modal-box">
        <form method="dialog" class="absolute right-3 top-3">
          <button class="btn btn-circle btn-ghost" @click.prevent="closeJoinModal" aria-label="Fermer le modal">✕</button>
        </form>

        <h3 class="font-bold text-lg mb-1">Rejoindre un groupe privé</h3>
        <p class="text-sm text-base-content/70 mb-4">Saisissez le code d’invitation transmis par un administrateur.</p>

        <div class="form-control">
          <label class="label" for="join-code">
            <span class="label-text">Code d’invitation</span>
          </label>
          <input
              id="join-code"
              v-model.trim="joinCode"
              type="text"
              placeholder="ABC12345"
              class="input input-bordered tracking-widest uppercase"
              @keydown.enter.prevent="handleJoinWithCode"
              autocomplete="one-time-code"
          />
        </div>

        <div v-if="joinError" class="alert alert-error mt-4">
          <span>{{ joinError }}</span>
        </div>

        <div class="modal-action">
          <button @click="closeJoinModal" class="btn btn-ghost">Annuler</button>
          <button
              @click="handleJoinWithCode"
              class="btn btn-primary"
              :disabled="!joinCode || joiningWithCode"
          >
            <span v-if="joiningWithCode" class="loading loading-spinner" aria-hidden></span>
            <span>{{ joiningWithCode ? 'Inscription…' : 'Rejoindre' }}</span>
          </button>
        </div>
      </div>
    </dialog>
  </div>
</template>

<script setup lang="ts">
import type { Team } from '~/types/database'

definePageMeta({ middleware: 'auth' })

const { getMyTeams, getPublicTeams, joinTeam, getTeamByJoinCode } = useTeams()

const activeTab = ref<'mine' | 'public'>('mine')

const myTeams = ref<Team[]>([])
const publicTeams = ref<Team[]>([])

const loadingMyTeams = ref(true)
const loadingPublicTeams = ref(true)
const joiningTeamId = ref<string | null>(null)

const showJoinModal = ref(false)
const joinDialog = ref<HTMLDialogElement | null>(null)
const joinCode = ref('')
const joiningWithCode = ref(false)
const joinError = ref('')

const publicSearch = ref('')

const filteredPublic = computed(() => {
  const q = publicSearch.value.trim().toLowerCase()
  if (!q) return publicTeams.value
  return publicTeams.value.filter((t) =>
      [t.name, t.description].filter(Boolean).some((v) => v!.toLowerCase().includes(q))
  )
})

onMounted(async () => {
  await Promise.all([reloadMine(), reloadPublic()])
})

async function reloadMine() {
  loadingMyTeams.value = true
  try {
    myTeams.value = await getMyTeams()
  } catch (e) {
    console.error('Error loading my teams:', e)
  } finally {
    loadingMyTeams.value = false
  }
}

async function reloadPublic() {
  loadingPublicTeams.value = true
  try {
    publicTeams.value = await getPublicTeams()
  } catch (e) {
    console.error('Error loading public teams:', e)
  } finally {
    loadingPublicTeams.value = false
  }
}

function isMyTeam(teamId: string) {
  return myTeams.value.some((team) => team.id === teamId)
}

async function handleJoinTeam(teamId: string) {
  joiningTeamId.value = teamId
  try {
    await joinTeam(teamId)
    await reloadMine()
  } catch (e: any) {
    alert(e.message || "Erreur lors de l'inscription au groupe")
  } finally {
    joiningTeamId.value = null
  }
}

function openJoinModal() {
  showJoinModal.value = true
  nextTick(() => joinDialog.value?.querySelector<HTMLInputElement>('#join-code')?.focus())
}

function closeJoinModal() {
  showJoinModal.value = false
  joinError.value = ''
}

async function handleJoinWithCode() {
  if (!joinCode.value) return
  joiningWithCode.value = true
  joinError.value = ''
  try {
    const team = await getTeamByJoinCode(joinCode.value.toUpperCase())
    await joinTeam(team.id, joinCode.value.toUpperCase())
    await reloadMine()
    showJoinModal.value = false
    const id = team.id
    joinCode.value = ''
    navigateTo(`/groups/${id}`)
  } catch (e: any) {
    joinError.value = e.message || "Code invalide ou erreur lors de l'inscription"
  } finally {
    joiningWithCode.value = false
  }
}

function clearSearch() {
  publicSearch.value = ''
}
</script>

<style scoped>
/* Subtle polish */
.tabs-boxed .tab { @apply px-4 py-2; }
</style>

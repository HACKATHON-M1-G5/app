<template>
  <div class="container mx-auto px-4 py-8">
    <div class="max-w-2xl mx-auto">
      <h1 class="text-3xl font-bold mb-8">Mon Profil</h1>

      <div v-if="userData" class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title text-2xl mb-4">{{ userData.username }}</h2>

          <div class="stats stats-vertical lg:stats-horizontal shadow mb-6">
            <div class="stat">
              <div class="stat-title">Tokens Globaux</div>
              <div class="stat-value text-primary">{{ userData.tokens }}</div>
              <div class="stat-desc">Utilisés pour les paris publics</div>
            </div>

            <div class="stat">
              <div class="stat-title">Taux de réussite</div>
              <div class="stat-value text-secondary">
                {{ (userData.winrate * 100).toFixed(1) }}%
              </div>
              <div class="stat-desc">Basé sur vos paris gagnants</div>
            </div>
          </div>

          <div class="divider"></div>

          <div class="form-control">
            <label class="label">
              <span class="label-text">Email</span>
            </label>
            <input type="email" :value="user?.email" class="input input-bordered" disabled />
          </div>

          <div class="form-control mt-4">
            <label class="label">
              <span class="label-text">Nom d'utilisateur</span>
            </label>
            <input
              v-model="newUsername"
              type="text"
              class="input input-bordered"
              :placeholder="userData.username"
            />
          </div>

          <div v-if="updateError" class="alert alert-error mt-4">
            <span>{{ updateError }}</span>
          </div>

          <div v-if="updateSuccess" class="alert alert-success mt-4">
            <span>{{ updateSuccess }}</span>
          </div>

          <div class="card-actions justify-end mt-6">
            <button
              class="btn btn-primary"
              :disabled="!newUsername || updating"
              @click="updateUsername"
            >
              <span v-if="updating" class="loading loading-spinner"></span>
              {{ updating ? 'Mise à jour...' : 'Mettre à jour' }}
            </button>
            <button class="btn btn-error" :disabled="loggingOut" @click="handleLogout">
              <span v-if="loggingOut" class="loading loading-spinner"></span>
              {{ loggingOut ? 'Déconnexion...' : 'Se déconnecter' }}
            </button>
          </div>
        </div>
      </div>

      <div v-else class="flex justify-center">
        <span class="loading loading-spinner loading-lg"></span>
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
const user = useSupabaseUser()
const { userData, refreshUserData } = useUserData()

const newUsername = ref('')
const updating = ref(false)
const updateError = ref('')
const updateSuccess = ref('')
const loggingOut = ref(false)

const updateUsername = async () => {
  if (!newUsername.value || !userData.value) return

  updating.value = true
  updateError.value = ''
  updateSuccess.value = ''

  try {
    const { error } = await supabase
      .from('UserDatas')
      .update({ username: newUsername.value })
      .eq('id', userData.value.id)

    if (error) throw error

    updateSuccess.value = "Nom d'utilisateur mis à jour !"
    newUsername.value = ''
    await refreshUserData()
  } catch (e: any) {
    updateError.value = e.message || 'Erreur lors de la mise à jour'
  } finally {
    updating.value = false
  }
}

const handleLogout = async () => {
  loggingOut.value = true

  try {
    await supabase.auth.signOut()
    await navigateTo('/login')
  } catch (e: any) {
    console.error('Logout error:', e)
  } finally {
    loggingOut.value = false
  }
}
</script>

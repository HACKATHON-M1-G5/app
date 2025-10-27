<template>
  <div class="container mx-auto px-4 py-8">
    <div class="max-w-2xl mx-auto">
      <h1 class="text-3xl font-bold mb-8">Créer un Groupe</h1>
      
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <form @submit.prevent="handleCreateTeam">
            <div class="form-control">
              <label class="label">
                <span class="label-text">Nom du groupe *</span>
              </label>
              <input 
                v-model="formData.name" 
                type="text" 
                placeholder="Les Parieurs Fous" 
                class="input input-bordered" 
                required
                maxlength="50"
              />
            </div>
            
            <div class="form-control mt-4">
              <label class="label">
                <span class="label-text">Description *</span>
              </label>
              <textarea 
                v-model="formData.description" 
                placeholder="Description de votre groupe..." 
                class="textarea textarea-bordered h-24" 
                required
                maxlength="200"
              ></textarea>
            </div>
            
            <div class="form-control mt-4">
              <label class="label">
                <span class="label-text">Couleur principale</span>
              </label>
              <input 
                v-model="formData.primary_color" 
                type="color" 
                class="input input-bordered w-full h-12" 
              />
            </div>
            
            <div class="form-control mt-4">
              <label class="label">
                <span class="label-text">URL de l'icône (optionnel)</span>
              </label>
              <input 
                v-model="formData.icon_url" 
                type="url" 
                placeholder="https://example.com/icon.png" 
                class="input input-bordered" 
              />
            </div>
            
            <div class="form-control mt-4">
              <label class="label cursor-pointer">
                <span class="label-text">Type de groupe</span>
                <input 
                  v-model="formData.privacy" 
                  type="checkbox" 
                  class="toggle toggle-primary" 
                />
              </label>
              <div class="text-sm opacity-70 mt-2">
                {{ formData.privacy ? '🔒 Privé - Nécessite un code d\'invitation' : '🌍 Public - Tout le monde peut rejoindre' }}
              </div>
            </div>
            
            <div v-if="error" class="alert alert-error mt-4">
              <span>{{ error }}</span>
            </div>
            
            <div class="card-actions justify-end mt-6">
              <NuxtLink to="/groups" class="btn btn-ghost">
                Annuler
              </NuxtLink>
              <button 
                type="submit" 
                class="btn btn-primary"
                :disabled="loading"
              >
                <span v-if="loading" class="loading loading-spinner"></span>
                {{ loading ? 'Création...' : 'Créer le groupe' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  middleware: 'auth',
})

const { createTeam } = useTeams()

const formData = ref({
  name: '',
  description: '',
  primary_color: '#3B82F6',
  icon_url: '',
  privacy: false,
})

const loading = ref(false)
const error = ref('')

const handleCreateTeam = async () => {
  loading.value = true
  error.value = ''
  
  try {
    const team = await createTeam(formData.value)
    await navigateTo(`/groups/${team.id}`)
  } catch (e: any) {
    error.value = e.message || 'Erreur lors de la création du groupe'
  } finally {
    loading.value = false
  }
}
</script>


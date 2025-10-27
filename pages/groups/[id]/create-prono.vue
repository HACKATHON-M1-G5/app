<template>
  <div class="container mx-auto px-4 py-8">
    <div class="max-w-2xl mx-auto">
      <h1 class="text-3xl font-bold mb-8">Créer un Pari</h1>
      
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <form @submit.prevent="handleCreateProno">
            <div class="form-control">
              <label class="label">
                <span class="label-text">Nom du pari *</span>
              </label>
              <input 
                v-model="formData.name" 
                type="text" 
                placeholder="Qui va gagner le match ?" 
                class="input input-bordered" 
                required
                maxlength="100"
              />
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Date de début *</span>
                </label>
                <input 
                  v-model="formData.start_at" 
                  type="datetime-local" 
                  class="input input-bordered" 
                  required
                />
              </div>
              
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Date de fin *</span>
                </label>
                <input 
                  v-model="formData.end_at" 
                  type="datetime-local" 
                  class="input input-bordered" 
                  required
                />
              </div>
            </div>
            
            <div class="divider">Options de pari</div>
            
            <div 
              v-for="(bet, index) in formData.bets" 
              :key="index"
              class="card bg-base-200 mb-4"
            >
              <div class="card-body p-4">
                <div class="flex justify-between items-start mb-2">
                  <h3 class="font-bold">Option {{ index + 1 }}</h3>
                  <button 
                    v-if="formData.bets.length > 1"
                    type="button"
                    @click="removeBet(index)" 
                    class="btn btn-ghost btn-xs btn-circle"
                  >
                    ✕
                  </button>
                </div>
                
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Titre *</span>
                  </label>
                  <input 
                    v-model="bet.title" 
                    type="text" 
                    placeholder="Équipe A gagne" 
                    class="input input-bordered input-sm" 
                    required
                  />
                </div>
                
                <div class="form-control mt-2">
                  <label class="label">
                    <span class="label-text">Cote * (ex: 2.5)</span>
                  </label>
                  <input 
                    v-model.number="bet.odds" 
                    type="number" 
                    step="0.1"
                    min="1.01"
                    placeholder="2.5" 
                    class="input input-bordered input-sm" 
                    required
                  />
                </div>
              </div>
            </div>
            
            <button 
              type="button"
              @click="addBet" 
              class="btn btn-outline btn-sm w-full"
            >
              ➕ Ajouter une option
            </button>
            
            <div v-if="error" class="alert alert-error mt-4">
              <span>{{ error }}</span>
            </div>
            
            <div class="card-actions justify-end mt-6">
              <NuxtLink :to="`/groups/${teamId}`" class="btn btn-ghost">
                Annuler
              </NuxtLink>
              <button 
                type="submit" 
                class="btn btn-primary"
                :disabled="loading || formData.bets.length < 2"
              >
                <span v-if="loading" class="loading loading-spinner"></span>
                {{ loading ? 'Création...' : 'Créer le pari' }}
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

const route = useRoute()
const teamId = route.params.id as string

const { createProno } = usePronos()

const formData = ref({
  name: '',
  start_at: '',
  end_at: '',
  bets: [
    { title: '', odds: 2.0 },
    { title: '', odds: 2.0 }
  ]
})

const loading = ref(false)
const error = ref('')

const addBet = () => {
  formData.value.bets.push({ title: '', odds: 2.0 })
}

const removeBet = (index: number) => {
  formData.value.bets.splice(index, 1)
}

const handleCreateProno = async () => {
  // Validation
  if (new Date(formData.value.start_at) >= new Date(formData.value.end_at)) {
    error.value = 'La date de fin doit être après la date de début'
    return
  }
  
  if (formData.value.bets.length < 2) {
    error.value = 'Vous devez créer au moins 2 options de pari'
    return
  }
  
  loading.value = true
  error.value = ''
  
  try {
    const prono = await createProno({
      name: formData.value.name,
      start_at: new Date(formData.value.start_at).toISOString(),
      end_at: new Date(formData.value.end_at).toISOString(),
      team_id: teamId,
      bets: formData.value.bets
    })
    
    await navigateTo(`/pronos/${prono.id}`)
  } catch (e: any) {
    error.value = e.message || 'Erreur lors de la création du pari'
  } finally {
    loading.value = false
  }
}
</script>


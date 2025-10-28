<template>
  <div class="container mx-auto px-4 py-8">
    <div class="max-w-3xl mx-auto">
      <div class="flex items-center gap-4 mb-8">
        <NuxtLink to="/admin" class="btn btn-ghost btn-circle">
          ← 
        </NuxtLink>
        <h1 class="text-3xl font-bold bg-gradient-to-r from-red-600 to-red-500 bg-clip-text text-transparent">
          Créer un Pari Public
        </h1>
      </div>
      
      <div class="card bg-base-100 shadow-xl border border-red-900/30">
        <div class="card-body">
          <form @submit.prevent="handleCreateProno">
            <!-- Informations de base -->
            <div class="form-control">
              <label class="label">
                <span class="label-text">Nom du pari *</span>
              </label>
              <input 
                v-model="formData.name" 
                type="text" 
                placeholder="Ex: Finale de la Champions League 2025" 
                class="input input-bordered" 
                required
                maxlength="200"
              />
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Date et heure de début *</span>
                </label>
                <input 
                  v-model="formData.start_at" 
                  type="datetime-local" 
                  class="input input-bordered" 
                  required
                />
                <label class="label">
                  <span class="label-text-alt">Les utilisateurs pourront parier jusqu'à cette date</span>
                </label>
              </div>
              
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Date et heure de fin *</span>
                </label>
                <input 
                  v-model="formData.end_at" 
                  type="datetime-local" 
                  class="input input-bordered" 
                  required
                />
                <label class="label">
                  <span class="label-text-alt">Fin de l'événement</span>
                </label>
              </div>
            </div>
            
            <div class="divider mt-6">Événement & Options proposées</div>

            <!-- Autocomplete événement -->
            <div class="form-control">
              <label class="label">
                <span class="label-text">Rechercher un événement (API externe)</span>
              </label>
              <input
                v-model="eventQuery"
                type="text"
                placeholder="Ex: PSG vs OM"
                class="input input-bordered"
                @input="handleEventSearch"
              />
              <div v-if="eventLoading" class="text-xs mt-1">Recherche...</div>
              <div v-if="eventOptions.length" class="mt-2">
                <select v-model.number="selectedEventId" class="select select-bordered w-full">
                  <option disabled :value="null">Sélectionner un événement</option>
                  <option v-for="ev in eventOptions" :key="ev.id" :value="ev.id">
                    {{ ev.name }}
                  </option>
                </select>
                <div class="mt-2">
                  <button type="button" class="btn btn-outline btn-sm" @click="importOptionsFromEvent" :disabled="!selectedEventId || importLoading">
                    <span v-if="importLoading" class="loading loading-spinner"></span>
                    📥 Importer l'événement (nom, dates et options)
                  </button>
                </div>
              </div>
              <label class="label">
                <span class="label-text-alt">L'import remplira automatiquement le nom, les dates et les options de pari</span>
              </label>
            </div>

            <div class="divider mt-6">Options de pari (cotes)</div>
            
            <!-- Liste des options -->
            <div class="space-y-4">
              <div 
                v-for="(bet, index) in formData.bets" 
                :key="index"
                class="card bg-base-200 border border-red-900/20"
              >
                <div class="card-body p-4">
                  <div class="flex justify-between items-start mb-2">
                    <h3 class="font-bold text-red-500">Option {{ index + 1 }}</h3>
                    <button 
                      v-if="formData.bets.length > 2"
                      type="button"
                      @click="removeBet(index)" 
                      class="btn btn-ghost btn-xs btn-circle"
                    >
                      ✕
                    </button>
                  </div>
                  
                  <div class="form-control">
                    <label class="label">
                      <span class="label-text">Nom de l'option *</span>
                    </label>
                    <input 
                      v-model="bet.title" 
                      type="text" 
                      placeholder="Ex: Victoire de l'équipe A" 
                      class="input input-bordered input-sm" 
                      required
                    />
                  </div>
                  
                  <div class="form-control mt-2">
                    <label class="label">
                      <span class="label-text">Cote * (multiplicateur de gain)</span>
                    </label>
                    <input 
                      v-model.number="bet.odds" 
                      type="number" 
                      step="0.01"
                      min="1.01"
                      placeholder="Ex: 2.5 (mise × 2.5 = gain)" 
                      class="input input-bordered input-sm" 
                      required
                    />
                    <label class="label">
                      <span class="label-text-alt">
                        Une cote de {{ bet.odds || 1 }}x signifie : 100 tokens misés = {{ Math.floor((bet.odds || 1) * 100) }} tokens gagnés
                      </span>
                    </label>
                  </div>
                </div>
              </div>
            </div>
            
            <button 
              type="button"
              @click="addBet" 
              class="btn btn-outline btn-sm w-full mt-4"
            >
              ➕ Ajouter une option
            </button>
            
            <!-- Aperçu -->
            <div class="alert alert-info mt-6">
              <div>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                <div>
                  <h3 class="font-bold">Conseils pour les cotes</h3>
                  <div class="text-xs mt-1">
                    • Cotes faibles (1.2-1.5) = Résultat probable<br>
                    • Cotes moyennes (2.0-3.0) = Résultat équilibré<br>
                    • Cotes élevées (4.0+) = Résultat improbable
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
              <NuxtLink to="/admin" class="btn btn-ghost">
                Annuler
              </NuxtLink>
              <button 
                type="submit" 
                class="btn btn-primary"
                :disabled="loading || formData.bets.length < 2"
              >
                <span v-if="loading" class="loading loading-spinner"></span>
                {{ loading ? 'Création...' : '✨ Créer le pari public' }}
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

const { createProno } = usePronos()

// Formater la date pour datetime-local (format: YYYY-MM-DDTHH:mm)
const formatDateTimeLocal = (date: Date) => {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')
  return `${year}-${month}-${day}T${hours}:${minutes}`
}

// Initialiser les dates avec l'heure actuelle
const now = new Date()
const inOneHour = new Date(now.getTime() + 60 * 60 * 1000) // +1 heure pour la fin

const formData = ref({
  name: '',
  start_at: formatDateTimeLocal(now),
  end_at: formatDateTimeLocal(inOneHour),
  bets: [
    { title: '', odds: 2.0 },
    { title: '', odds: 2.0 }
  ]
})

// External events search/import
const { searchEvents, getEventOptions, getEvent } = useExternalEvents()
const eventQuery = ref('')
const eventOptions = ref<Array<{ id: number; name: string }>>([])
const selectedEventId = ref<number | null>(null)
const eventLoading = ref(false)
const importLoading = ref(false)

let eventSearchTimeout: any
const handleEventSearch = () => {
  if (eventSearchTimeout) clearTimeout(eventSearchTimeout)
  eventLoading.value = true
  eventSearchTimeout = setTimeout(async () => {
    try {
      const results = eventQuery.value ? await searchEvents(eventQuery.value) : []
      eventOptions.value = results
    } catch (e: any) {
      error.value = e.message || 'Erreur lors de la recherche des événements'
    } finally {
      eventLoading.value = false
    }
  }, 300)
}

const importOptionsFromEvent = async () => {
  if (!selectedEventId.value) return
  importLoading.value = true
  error.value = ''
  success.value = ''
  try {
    // Récupérer l'événement pour avoir ses informations complètes
    const event = await getEvent(selectedEventId.value)
    
    let importedItems: string[] = []
    
    // Appliquer le nom de l'événement au prono
    if (event.name) {
      formData.value.name = event.name
      importedItems.push('nom')
    }
    
    // Appliquer les dates de l'événement
    if (event.start_at) {
      const startDate = new Date(event.start_at)
      formData.value.start_at = formatDateTimeLocal(startDate)
      importedItems.push('date de début')
    }
    
    if (event.end_at_expected) {
      const endDate = new Date(event.end_at_expected)
      formData.value.end_at = formatDateTimeLocal(endDate)
      importedItems.push('date de fin')
    }
    
    // Récupérer les options de pari
    const options = await getEventOptions(selectedEventId.value)
    if (options && options.length) {
      formData.value.bets = options.map((opt: any) => ({ 
        title: opt.name || opt.label || opt.description || '', 
        odds: 2.0 
      }))
      importedItems.push(`${options.length} option(s)`)
    } else {
      error.value = "Aucune option disponible pour cet événement (vous pouvez les créer manuellement)"
    }
    
    if (importedItems.length > 0) {
      success.value = `✅ Importé avec succès : ${importedItems.join(', ')}`
      // Effacer le message de succès après 3 secondes
      setTimeout(() => {
        success.value = ''
      }, 3000)
    }
  } catch (e: any) {
    error.value = e.message || "Erreur lors de l'import des données de l'événement"
  } finally {
    importLoading.value = false
  }
}

const loading = ref(false)
const error = ref('')
const success = ref('')

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
  
  // Vérifier que toutes les cotes sont valides
  const invalidOdds = formData.value.bets.some(b => !b.title || b.odds < 1.01)
  if (invalidOdds) {
    error.value = 'Toutes les options doivent avoir un nom et une cote >= 1.01'
    return
  }
  
  loading.value = true
  error.value = ''
  success.value = ''
  
  try {
    const prono = await createProno({
      name: formData.value.name,
      start_at: new Date(formData.value.start_at).toISOString(),
      end_at: new Date(formData.value.end_at).toISOString(),
      team_id: null, // Pari public
      event_id: selectedEventId.value ? String(selectedEventId.value) : null,
      bets: formData.value.bets
    })
    
    success.value = 'Pari public créé avec succès ! Redirection...'
    
    setTimeout(() => {
      navigateTo(`/pronos/${prono.id}`)
    }, 1500)
  } catch (e: any) {
    error.value = e.message || 'Erreur lors de la création du pari'
  } finally {
    loading.value = false
  }
}
</script>



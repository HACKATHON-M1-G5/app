<template>
  <div class="min-h-screen flex items-center justify-center bg-base-200">
    <div class="card w-96 bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title text-2xl font-bold text-center justify-center mb-4">
          Connexion
        </h2>
        
        <form @submit.prevent="handleLogin">
          <div class="form-control">
            <label class="label">
              <span class="label-text">Email</span>
            </label>
            <input 
              v-model="email" 
              type="email" 
              placeholder="email@exemple.com" 
              class="input input-bordered" 
              required
            />
          </div>
          
          <div class="form-control mt-4">
            <label class="label">
              <span class="label-text">Mot de passe</span>
            </label>
            <input 
              v-model="password" 
              type="password" 
              placeholder="••••••••" 
              class="input input-bordered" 
              required
            />
          </div>
          
          <div v-if="error" class="alert alert-error mt-4">
            <span>{{ error }}</span>
          </div>
          
          <div class="form-control mt-6">
            <button 
              type="submit" 
              class="btn btn-primary"
              :disabled="loading"
            >
              <span v-if="loading" class="loading loading-spinner"></span>
              {{ loading ? 'Connexion...' : 'Se connecter' }}
            </button>
          </div>
        </form>
        
        <div class="divider">OU</div>
        
        <NuxtLink to="/register" class="btn btn-ghost">
          Créer un compte
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: false,
})

const supabase = useSupabaseClient()
const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

const handleLogin = async () => {
  loading.value = true
  error.value = ''
  
  try {
    const { error: loginError } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value,
    })
    
    if (loginError) throw loginError
    
    await navigateTo('/')
  } catch (e: any) {
    error.value = e.message || 'Erreur lors de la connexion'
  } finally {
    loading.value = false
  }
}
</script>


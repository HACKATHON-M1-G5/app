<template>
  <div class="min-h-screen flex items-center justify-center bg-base-200">
    <div class="card w-96 bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title text-2xl font-bold text-center justify-center mb-4">
          Inscription
        </h2>
        
        <form @submit.prevent="handleRegister">
          <div class="form-control">
            <label class="label">
              <span class="label-text">Nom d'utilisateur</span>
            </label>
            <input 
              v-model="username" 
              type="text" 
              placeholder="JohnDoe" 
              class="input input-bordered" 
              required
              minlength="3"
            />
          </div>
          
          <div class="form-control mt-4">
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
              minlength="6"
            />
          </div>
          
          <div class="form-control mt-4">
            <label class="label">
              <span class="label-text">Confirmer le mot de passe</span>
            </label>
            <input 
              v-model="confirmPassword" 
              type="password" 
              placeholder="••••••••" 
              class="input input-bordered" 
              required
            />
          </div>
          
          <div v-if="error" class="alert alert-error mt-4">
            <span>{{ error }}</span>
          </div>
          
          <div v-if="success" class="alert alert-success mt-4">
            <span>{{ success }}</span>
          </div>
          
          <div class="form-control mt-6">
            <button 
              type="submit" 
              class="btn btn-primary"
              :disabled="loading"
            >
              <span v-if="loading" class="loading loading-spinner"></span>
              {{ loading ? 'Inscription...' : "S'inscrire" }}
            </button>
          </div>
        </form>
        
        <div class="divider">OU</div>
        
        <NuxtLink to="/login" class="btn btn-ghost">
          Déjà un compte ? Se connecter
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
const username = ref('')
const email = ref('')
const password = ref('')
const confirmPassword = ref('')
const loading = ref(false)
const error = ref('')
const success = ref('')

const handleRegister = async () => {
  loading.value = true
  error.value = ''
  success.value = ''
  
  try {
    // Validation
    if (password.value !== confirmPassword.value) {
      throw new Error('Les mots de passe ne correspondent pas')
    }
    
    if (password.value.length < 6) {
      throw new Error('Le mot de passe doit contenir au moins 6 caractères')
    }
    
    if (username.value.length < 3) {
      throw new Error("Le nom d'utilisateur doit contenir au moins 3 caractères")
    }
    
    const { error: signUpError } = await supabase.auth.signUp({
      email: email.value,
      password: password.value,
      options: {
        data: {
          username: username.value,
        },
      },
    })
    
    if (signUpError) throw signUpError
    
    success.value = 'Compte créé avec succès ! Redirection...'
    
    setTimeout(() => {
      navigateTo('/')
    }, 2000)
  } catch (e: any) {
    error.value = e.message || "Erreur lors de l'inscription"
  } finally {
    loading.value = false
  }
}
</script>


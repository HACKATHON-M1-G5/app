export default defineNuxtRouteMiddleware(async (to) => {
  const user = useSupabaseUser()
  
  // Pages publiques accessibles sans authentification
  const publicPages = ['/login', '/register']
  
  if (!user.value && !publicPages.includes(to.path)) {
    return navigateTo('/login')
  }
  
  if (user.value && publicPages.includes(to.path)) {
    return navigateTo('/')
  }
})


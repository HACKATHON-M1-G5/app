<template>
  <div class="container mx-auto px-4 py-8">
    <h1 class="text-3xl font-bold mb-8">Paris Publics</h1>

    <div v-if="loading" class="flex justify-center py-8">
      <span class="loading loading-spinner loading-lg"></span>
    </div>

    <div v-else-if="pronos.length === 0" class="alert alert-info">
      <span>Aucun pari public disponible pour le moment.</span>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <PronoCard v-for="prono in pronos" :key="prono.id" :prono="prono" />
    </div>
  </div>
</template>

<script setup lang="ts">
import type { PronoWithBets } from '~/types/database'

definePageMeta({
  middleware: 'auth',
})

const { getPublicPronos } = usePronos()
const { subscribeToPublicPronos, unsubscribeAll } = useRealtime()

const pronos = ref<PronoWithBets[]>([])
const loading = ref(true)

onMounted(async () => {
  await loadPronos()

  // 📡 S'abonner aux changements en temps réel
  subscribeToPublicPronos(async () => {
    console.log('🔄 Mise à jour temps réel des paris publics')
    await loadPronos()
  })
})

onUnmounted(() => {
  // 🔌 Se désabonner quand on quitte la page
  unsubscribeAll()
})

const loadPronos = async () => {
  loading.value = true

  try {
    pronos.value = await getPublicPronos()
  } catch (e) {
    console.error('Error loading public pronos:', e)
  } finally {
    loading.value = false
  }
}
</script>

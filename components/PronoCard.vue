<template>
  <div class="card bg-base-100 shadow-xl hover:shadow-2xl transition-shadow">
    <div class="card-body">
      <h2 class="card-title">
        {{ prono.name }}
        <div v-if="isActive" class="badge badge-success">En cours</div>
        <div v-else-if="isPending" class="badge badge-warning">À venir</div>
        <div v-else class="badge badge-error">Terminé</div>
      </h2>
      
      <div class="text-sm opacity-70 space-y-1">
        <p>📅 Début : {{ formatDate(prono.start_at) }}</p>
        <p>🏁 Fin : {{ formatDate(prono.end_at) }}</p>
        <p v-if="prono.owner">👤 Créé par : {{ prono.owner.username }}</p>
        <p v-if="prono.team">🏆 Groupe : {{ prono.team.name }}</p>
        <p v-else>🌍 Paris Public</p>
      </div>
      
      <div v-if="prono.bets && prono.bets.length > 0" class="mt-3">
        <div class="badge badge-outline">
          🎯 {{ prono.bets.length }} option{{ prono.bets.length > 1 ? 's' : '' }} de pari
        </div>
      </div>
      
      <div class="card-actions justify-end mt-4">
        <slot name="actions">
          <NuxtLink :to="`/pronos/${prono.id}`" class="btn btn-primary btn-sm">
            {{ isActive ? 'Parier maintenant' : 'Voir les détails' }}
          </NuxtLink>
        </slot>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { PronoWithBets } from '~/types/database'

const props = defineProps<{
  prono: PronoWithBets
}>()

const now = new Date()
const startDate = new Date(props.prono.start_at)
const endDate = new Date(props.prono.end_at)

const isPending = computed(() => now < startDate)
const isActive = computed(() => now >= startDate && now <= endDate)

const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}
</script>


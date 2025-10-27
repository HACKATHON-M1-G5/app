<template>
  <div class="card bg-base-100 shadow-xl hover:shadow-2xl transition-shadow">
    <div class="card-body">
      <div class="flex items-start gap-4">
        <div 
          class="avatar placeholder"
          :style="{ backgroundColor: team.primary_color }"
        >
          <div class="w-16 rounded-xl text-white">
            <span v-if="!team.icon_url" class="text-2xl">{{ team.name[0] }}</span>
            <img v-else :src="team.icon_url" :alt="team.name" />
          </div>
        </div>
        
        <div class="flex-1">
          <h2 class="card-title">
            {{ team.name }}
            <div class="badge badge-secondary" v-if="team.privacy">Privé</div>
            <div class="badge badge-success" v-else>Public</div>
          </h2>
          <p class="text-sm opacity-70 mt-2">{{ team.description }}</p>
          
          <div v-if="memberCount !== undefined" class="mt-3">
            <div class="badge badge-outline">
              👥 {{ memberCount }} membre{{ memberCount > 1 ? 's' : '' }}
            </div>
          </div>
        </div>
      </div>
      
      <div class="card-actions justify-end mt-4">
        <slot name="actions">
          <NuxtLink :to="`/groups/${team.id}`" class="btn btn-primary btn-sm">
            Voir le groupe
          </NuxtLink>
        </slot>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Team } from '~/types/database'

defineProps<{
  team: Team
  memberCount?: number
}>()
</script>


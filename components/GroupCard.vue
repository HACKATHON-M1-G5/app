<template>
  <div class="card bg-base-100 shadow-xl hover:shadow-2xl transition-shadow">
    <div class="card-body">
      <div class="flex flex-col sm:flex-row items-start gap-4">
        <div class="avatar placeholder" :style="{ backgroundColor: team.primary_color }">
          <div class="w-14 sm:w-16 rounded-xl text-white">
            <span v-if="!team.icon_url" class="text-2xl">{{ team.name[0] }}</span>
            <img v-else :src="team.icon_url" :alt="team.name" />
          </div>
        </div>

        <div class="flex-1">
          <h2 class="card-title text-lg sm:text-xl">
            {{ team.name }}
            <div v-if="team.privacy" class="badge badge-secondary">Privé</div>
            <div v-else class="badge badge-success">Public</div>
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
          <NuxtLink :to="`/groups/${team.id}`" class="btn btn-primary btn-xs sm:btn-sm">
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

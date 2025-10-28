<template>
  <div class="card bg-base-100 border-2 border-base-300 hover:border-primary transition-colors">
    <div class="card-body p-4">
      <div class="flex flex-col sm:flex-row sm:justify-between sm:items-start gap-3">
        <div class="flex-1">
          <h3 class="font-bold text-base sm:text-lg">{{ bet.title }}</h3>
          <p class="text-sm opacity-70 mt-1">Cote : {{ bet.odds }}x</p>

          <div v-if="stats" class="mt-2 text-sm">
            <p class="opacity-70">💰 Total misé : {{ stats.totalAmount }} tokens</p>
            <p class="opacity-70">
              👥 {{ stats.betCount }} pari{{ stats.betCount > 1 ? 's' : '' }}
            </p>
          </div>
        </div>

        <div
          v-if="bet.result !== null"
          class="badge"
          :class="{
            'badge-success': bet.result === true,
            'badge-error': bet.result === false,
          }"
        >
          {{ bet.result ? '✓ Gagné' : '✗ Perdu' }}
        </div>
      </div>

      <div v-if="canBet" class="mt-4">
        <div class="form-control">
          <label class="label">
            <span class="label-text">Montant à parier</span>
          </label>
          <div class="input-group">
            <input
              v-model.number="amount"
              type="number"
              min="1"
              :max="maxAmount"
              placeholder="100"
              class="input input-bordered w-full"
            />
            <span class="btn btn-ghost">tokens</span>
          </div>
          <label v-if="amount > 0" class="label">
            <span class="label-text-alt text-success">
              Gain potentiel : {{ calculateWin }} tokens
            </span>
          </label>
        </div>

        <button
          class="btn btn-primary w-full mt-2"
          :disabled="!amount || amount <= 0 || amount > maxAmount || loading"
          @click="handlePlaceBet"
        >
          <span v-if="loading" class="loading loading-spinner"></span>
          {{ loading ? 'Pari en cours...' : 'Placer le pari' }}
        </button>
      </div>

      <slot name="actions"></slot>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Bet } from '~/types/database'

const props = defineProps<{
  bet: Bet
  canBet?: boolean
  maxAmount?: number
  stats?: { totalAmount: number; betCount: number }
}>()

const emit = defineEmits<{
  placeBet: [amount: number]
}>()

const amount = ref<number>(0)
const loading = ref(false)

const calculateWin = computed(() => {
  if (!amount.value || amount.value <= 0) return 0
  return Math.floor(amount.value * props.bet.odds)
})

const handlePlaceBet = () => {
  if (!amount.value || amount.value <= 0) return
  emit('placeBet', amount.value)
}

defineExpose({
  setLoading: (value: boolean) => {
    loading.value = value
  },
  resetAmount: () => {
    amount.value = 0
  },
})
</script>

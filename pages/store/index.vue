<template>
  <div class="container mx-auto px-4 py-8">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Boutique</h1>
        <p class="text-sm text-base-content/60 mt-1">Échangez vos tokens contre des items. Gagnez des tokens en regardant une vidéo.</p>
      </div>
      <button class="btn btn-outline gap-2" @click="openRewardModal">
        <PlayIcon class="w-4 h-4" />
        Gagner des tokens
      </button>
    </div>

    <!-- Controls -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-3 mb-6">
      <div class="tabs tabs-boxed">
        <button class="tab h-auto" :class="{ 'tab-active': activeTab === 'all' }" @click="activeTab = 'all'">Tous</button>
        <button class="tab h-auto" :class="{ 'tab-active': activeTab === 'cosmetics' }" @click="activeTab = 'cosmetics'">Cosmétique</button>
        <button class="tab h-auto" :class="{ 'tab-active': activeTab === 'boosts' }" @click="activeTab = 'boosts'">Boosts</button>
        <button class="tab h-auto" :class="{ 'tab-active': activeTab === 'privileges' }" @click="activeTab = 'privileges'">Privilèges</button>
      </div>

      <div class="w-full md:w-96 flex gap-2">
        <label class="input input-bordered flex items-center gap-2 grow">
          <span class="w-5 h-5 opacity-60" aria-hidden>🔍</span>
          <input v-model.trim="q" type="search" placeholder="Rechercher un item…" class="grow" @keyup.enter="reloadItems" />
          <button v-if="q" class="btn btn-ghost btn-sm" @click="q='';">Effacer</button>
        </label>
        <select v-model="sort" class="select select-bordered w-44">
          <option value="recent">Plus récents</option>
          <option value="cheap">Moins chers</option>
          <option value="expensive">Plus chers</option>
        </select>
      </div>
    </div>

    <!-- Items Grid -->
    <section>
      <div v-if="loading" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        <div v-for="n in 6" :key="n" class="card bg-base-100 border border-base-200 animate-pulse">
          <div class="aspect-[16/9] bg-base-200" />
          <div class="card-body">
            <div class="h-6 bg-base-200 rounded w-3/4 mb-2" />
            <div class="h-4 bg-base-200 rounded w-full mb-1" />
            <div class="h-4 bg-base-200 rounded w-full mb-4" />
            <div class="flex items-center justify-between">
              <div class="h-6 bg-base-200 rounded w-16" />
              <div class="h-8 bg-base-200 rounded w-20" />
            </div>
          </div>
        </div>
      </div>

      <div v-else-if="filteredItems.length === 0" class="alert">
        <div class="flex items-start gap-3">
          <span class="text-2xl" aria-hidden>🪄</span>
          <div>
            <h3 class="font-semibold">Aucun résultat</h3>
            <p class="text-base-content/70">Ajustez vos filtres ou réessayez plus tard.</p>
          </div>
        </div>
      </div>

      <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        <article v-for="item in filteredItems" :key="item.id" class="card bg-base-100 border border-base-200">
          <figure class="aspect-[16/9] overflow-hidden bg-base-200">
            <img :src="item.image || placeholder" :alt="item.name" class="w-full h-full object-cover" />
          </figure>
          <div class="card-body">
            <div class="flex items-start justify-between gap-3">
              <div>
                <h3 class="card-title text-base">{{ item.name }}</h3>
                <p class="text-sm text-base-content/70 line-clamp-2">{{ item.description }}</p>
              </div>
              <div class="badge badge-ghost gap-1 whitespace-nowrap">
                💰<span class="font-semibold">{{ item.price }}</span>
              </div>
            </div>

            <div class="mt-3 flex items-center justify-between">
              <div class="flex gap-2">
                <span class="badge badge-outline">{{ prettyCategory(item.category) }}</span>
                <span v-if="item.limited" class="badge badge-warning">Limité</span>
              </div>
              <button
                  class="btn btn-primary btn-sm"
                  :disabled="purchasingId === item.id || balance < item.price"
                  @click="purchase(item)"
              >
                <span v-if="purchasingId === item.id" class="loading loading-spinner loading-xs" aria-hidden />
                <span>{{ balance < item.price ? 'Insuffisant' : 'Acheter' }}</span>
              </button>
            </div>
          </div>
        </article>
      </div>
    </section>

    <!-- Rewarded Video Modal -->
    <dialog ref="rewardDialog" :open="showReward" class="modal" @click.self="closeReward">
      <div class="modal-box max-w-3xl">
        <form method="dialog" class="absolute right-3 top-3">
          <button class="btn btn-circle btn-ghost" @click.prevent="closeReward" aria-label="Fermer">✕</button>
        </form>

        <h3 class="font-bold text-lg mb-1">Regarder une vidéo pour gagner des tokens</h3>
        <p class="text-sm text-base-content/70 mb-4">Restez jusqu’à la fin pour débloquer la récompense.</p>

        <div class="rounded-xl overflow-hidden border border-base-200">
          <video
              ref="videoRef"
              class="w-full h-auto bg-black"
              :src="videoSrc"
              playsinline
              @timeupdate="onTimeUpdate"
              @ended="onEnded"
          />
        </div>

        <div class="mt-4 flex items-center justify-between">
          <div class="text-sm text-base-content/70">Progression: {{ watchedPct }}%</div>
          <div class="modal-action">
            <button class="btn btn-ghost" @click="closeReward">Annuler</button>
            <button class="btn btn-primary" :disabled="!canClaim" @click="claimReward">
              💰
              +{{ rewardAmount }} tokens
            </button>
          </div>
        </div>

        <p v-if="rewardError" class="mt-2 text-error text-sm">{{ rewardError }}</p>
      </div>
    </dialog>
  </div>
</template>

<script setup lang="ts">
import {computed, defineComponent, h, nextTick, onMounted, ref} from 'vue'
import {type ShopItem, useShop} from "~/composables/useShop";

// Composables attendus côté app
// useShop: { getItems, purchaseItem }
const { balance, addTokens, refreshBalance } = useTokens()
const { getItems, purchaseItem } = useShop()

const placeholder = 'https://picsum.photos/640/360?grayscale'

// UI state
const activeTab = ref<'all' | 'cosmetics' | 'boosts' | 'privileges'>('all')
const q = ref('')
const sort = ref<'recent' | 'cheap' | 'expensive'>('recent')

// Data
const items = ref<ShopItem[]>([])
const loading = ref(true)
const purchasingId = ref<string | null>(null)

// Rewarded video state (mock)
const showReward = ref(false)
const rewardDialog = ref<HTMLDialogElement | null>(null)
const videoRef = ref<HTMLVideoElement | null>(null)
const watchedPct = ref(0)
const canClaim = ref(false)
const rewardError = ref('')
const rewardAmount = 25
const minWatchPct = 90
const videoSrc = '/vids/pub.mp4'

onMounted(async () => {
  await reloadItems()
})

async function reloadItems() {
  loading.value = true
  try {
    items.value = await getItems()
  } finally {
    loading.value = false
  }
}

const filteredItems = computed(() => {
  let list = items.value.slice()

  // Onglets (catégories)
  if (activeTab.value !== 'all') {
    list = list.filter(i => i.category === activeTab.value)
  }

  // Recherche
  const query = q.value.toLowerCase()
  if (query) {
    list = list.filter(i =>
        [i.name, i.description].filter(Boolean).some(v => v!.toLowerCase().includes(query))
    )
  }

  // Tri
  if (sort.value === 'cheap') list.sort((a,b) => a.price - b.price)
  else if (sort.value === 'expensive') list.sort((a,b) => b.price - a.price)
  else list.sort((a,b) => (b.created_at ?? 0) - (a.created_at ?? 0))

  return list
})

function prettyCategory(cat?: ShopItem['category']) {
  switch (cat) {
    case 'cosmetics': return 'Cosmétique'
    case 'boosts': return 'Boost'
    case 'privileges': return 'Privilège'
    default: return 'Item'
  }
}

async function purchase(item: ShopItem) {
  if (balance.value < item.price) return
  purchasingId.value = item.id
  try {
    await purchaseItem(item.id)
    await refreshBalance()
  } catch (e: any) {
    alert(e?.message || 'Erreur lors de l\'achat')
  } finally {
    purchasingId.value = null
  }
}

function openRewardModal() {
  rewardError.value = ''
  watchedPct.value = 0
  canClaim.value = false
  showReward.value = true
  videoRef.value!.currentTime = 0
  nextTick(() => videoRef.value?.play().catch(() => {/* autoplay blocked */}))
}

function closeReward() {
  try { videoRef.value?.pause() } catch {}
  showReward.value = false
}

function onTimeUpdate() {
  const v = videoRef.value
  if (!v || !v.duration || Number.isNaN(v.duration)) return
  const pct = Math.floor((v.currentTime / v.duration) * 100)
  watchedPct.value = Math.min(100, Math.max(0, pct))
  canClaim.value = watchedPct.value >= minWatchPct
}

function onEnded() {
  onTimeUpdate()
}

async function claimReward() {
  if (!canClaim.value) {
    rewardError.value = `Vous devez regarder au moins ${minWatchPct}% de la vidéo.`
    return
  }
  try {
    await addTokens(rewardAmount)
    await refreshBalance()
    closeReward()
  } catch (e: any) {
    rewardError.value = e?.message || 'Impossible d\'attribuer la récompense.'
  }
}

const PlayIcon = defineComponent({ name:'PlayIcon', setup(){ return () => h('svg', { xmlns:'http://www.w3.org/2000/svg', viewBox:'0 0 24 24' }, [
    h('path', { fill:'currentColor', d:'M8 5.14v13.72c0 .8.87 1.3 1.56.87l10.3-6.86a1 1 0 0 0 0-1.74L9.56 4.27A1 1 0 0 0 8 5.14z' })
  ])}})
</script>

<style scoped>
.tabs-boxed .tab { @apply px-4 py-2; }
</style>

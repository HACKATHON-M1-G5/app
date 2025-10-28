import type { UserData } from '~/types/database'

export const useTokens = () => {
    const supabase = useSupabaseClient()
    const { whenUserDataReady } = useUserData()

    // État réactif du solde
    const balance = ref<number>(0)

    // Référence au canal realtime pour cleanly unsubscribe
    let rtChannel: ReturnType<ReturnType<typeof useRealtime>['subscribeToUserData']> | null = null

    /** S'assure qu'on a un UserData, sinon throw */
    const ensureUser = async (): Promise<UserData> => {
        const ud = await whenUserDataReady()
        if (!ud) throw new Error('User not authenticated')
        return ud
    }

    /** Recharge le solde depuis la DB (utile après mutation si pas de realtime) */
    const refreshBalance = async (): Promise<number> => {
        const user = await ensureUser()
        const { data, error } = await supabase
            .from('UserDatas')
            .select('tokens')
            .eq('id', user.id)
            .single()

        if (error) {
            console.error('Error refreshing balance:', error)
            throw error
        }
        balance.value = data?.tokens ?? 0
        return balance.value
    }

    /** Vérifie si l'utilisateur a assez de tokens */
    const userHasTokens = async (amount: number): Promise<boolean> => {
        if (amount <= 0) return true
        // Option 1: se baser sur la valeur locale (rapide)
        // return balance.value >= amount
        // Option 2: sécurité: rafraîchir avant de décider
        await refreshBalance()
        return balance.value >= amount
    }

    /**
     * Déduit des tokens (retourne true si OK).
     * Note: cette version calcule tokens = valeur courante - amount.
     * Pour éviter toute condition de course multi-requêtes, l’idéal est d’utiliser une RPC SQL atomique.
     */
    const deductTokens = async (amount: number): Promise<boolean> => {
        if (amount <= 0) return true
        const user = await ensureUser()

        // Vérif côté client
        await refreshBalance()
        if (balance.value < amount) return false

        const newTokens = balance.value - amount

        const { data, error } = await supabase
            .from('UserDatas')
            .update({ tokens: newTokens })
            .eq('id', user.id)
            .select('tokens')
            .single()

        if (error) {
            console.error('Error deducting tokens:', error)
            throw error
        }

        // MAJ locale
        balance.value = data?.tokens ?? newTokens
        return true
    }

    /**
     * Ajoute des tokens (retourne true si OK).
     * meta est optionnel pour log/analytics si tu veux l’utiliser côté serveur.
     */
    const addTokens = async (amount: number, _meta?: Record<string, unknown>): Promise<boolean> => {
        if (amount <= 0) return true
        const user = await ensureUser()

        // On part de la valeur locale (rafraîchie si nécessaire)
        await refreshBalance()
        const newTokens = balance.value + amount

        const { data, error } = await supabase
            .from('UserDatas')
            .update({ tokens: newTokens })
            .eq('id', user.id)
            .select('tokens')
            .single()

        if (error) {
            console.error('Error adding tokens:', error)
            throw error
        }

        balance.value = data?.tokens ?? newTokens
        return true
    }

    // Lifecycle (client only)
    onMounted(async () => {
        const { subscribeToUserData } = useRealtime()
        const user = await ensureUser()

        // Init du solde (évite de rappeler ensureUser 2x)
        balance.value = user.tokens ?? 0

        // Souscription realtime propre — on garde la ref du canal
        rtChannel = subscribeToUserData(user.id, (newUserData: UserData) => {
            if (typeof newUserData?.tokens === 'number') {
                balance.value = newUserData.tokens
            }
        })
    })

    onUnmounted(() => {
        // Unsubscribe correctement au lieu de passer un nom de table
        if (rtChannel && typeof rtChannel.unsubscribe === 'function') {
            try { rtChannel.unsubscribe() } catch { /* noop */ }
        } else {
            // compat : si ton useRealtime expose un fallback
            const { unsubscribe } = useRealtime()
            try { unsubscribe('UserDatas') } catch { /* noop */ }
        }
    })

    return {
        balance,
        refreshBalance,
        userHasTokens,
        deductTokens,
        addTokens,
    }
}

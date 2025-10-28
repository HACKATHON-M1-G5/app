import type {UserData} from "~/types/database";

export const useTokens = () => {
    const supabase = useSupabaseClient()
    const { whenUserDataReady } = useUserData()
    const balance = ref(0);

    const ensureUser = async () => {
        const ud = await whenUserDataReady()
        if (!ud) throw new Error('User not authenticated')
        return ud
    }

    const refreshBalance = async () => {
        const userData: UserData = await ensureUser()
        const { data, error } = await supabase
            .from('UserDatas')
            .select('tokens')
            .eq('id', userData.id)
            .single()
        if (error) {
            throw error
        }
        balance.value = data.tokens
    }

    const userHasTokens = async (amount :number) : Promise<Boolean> => {
        const userData: UserData = await ensureUser()
        return (userData.tokens >= amount)
    }

    const deductTokens = async (amount :number) : Promise<Boolean> => {
        const userData: UserData = await ensureUser()
        if (userData.tokens < amount) {
            return false
        }
        const { error } = await supabase
            .from('UserDatas')
            .update({ tokens: userData.tokens - amount })
            .eq('id', userData.id)
        if (error) {
            throw error
        }
        return true
    }

    const addTokens = async (amount :number) : Promise<Boolean> => {
        const userData: UserData = await ensureUser()
        const { error } = await supabase
            .from('UserDatas')
            .update({ tokens: userData.tokens + amount })
            .eq('id', userData.id)
        if (error) {
            throw error
        }
        return true
    }

    onMounted(() => {
        refreshBalance()
    })

    return {
        balance,
        refreshBalance,
        userHasTokens,
        deductTokens,
        addTokens,
    }
}


import type { BetUserData, UserBetWithDetails } from '~/types/database'

export const useBets = () => {
  const supabase = useSupabaseClient()
  const { userData, refreshUserData } = useUserData()
  const { getUserTeamTokens } = useTeams()

  const placeBet = async (
    betId: string,
    amount: number,
    pronoId: string,
    teamId: string | null
  ) => {
    if (!userData.value) throw new Error('User not authenticated')

    // Check if user has enough tokens
    let availableTokens = 0
    
    if (teamId) {
      // Group bet - use team tokens
      availableTokens = await getUserTeamTokens(teamId)
    } else {
      // Public bet - use global tokens
      availableTokens = userData.value.tokens
    }

    if (availableTokens < amount) {
      throw new Error('Tokens insuffisants')
    }

    // Create bet
    const { error: betError } = await supabase
      .from('bet_userdata')
      .insert({
        bet_id: betId,
        userdata_id: userData.value.id,
        amount: amount,
        created_at: Date.now(),
      })

    if (betError) throw betError

    // Deduct tokens
    if (teamId) {
      // Deduct from team tokens
      const { error: tokenError } = await supabase
        .from('team_userdata')
        .update({ token: availableTokens - amount })
        .eq('team_id', teamId)
        .eq('userdata_id', userData.value.id)

      if (tokenError) throw tokenError
    } else {
      // Deduct from global tokens
      const { error: tokenError } = await supabase
        .from('UserDatas')
        .update({ tokens: availableTokens - amount })
        .eq('id', userData.value.id)

      if (tokenError) throw tokenError

      await refreshUserData()
    }

    return true
  }

  const getUserBets = async () => {
    if (!userData.value) return []

    const { data, error } = await supabase
      .from('bet_userdata')
      .select(`
        *,
        bet:Bets (
          *,
          prono:Pronos (
            *,
            team:Teams (*)
          )
        )
      `)
      .eq('userdata_id', userData.value.id)
      .order('created_at', { ascending: false })

    if (error) throw error

    return data as UserBetWithDetails[]
  }

  const getUserBetsByProno = async (pronoId: string) => {
    if (!userData.value) return []

    const { data, error } = await supabase
      .from('bet_userdata')
      .select(`
        *,
        bet:Bets!inner (*)
      `)
      .eq('userdata_id', userData.value.id)
      .eq('bet.prono_id', pronoId)

    if (error) throw error

    return data as BetUserData[]
  }

  const getBetStats = async (betId: string) => {
    const { data, error } = await supabase
      .from('bet_userdata')
      .select('amount')
      .eq('bet_id', betId)

    if (error) throw error

    const totalAmount = data.reduce((sum, bet) => sum + bet.amount, 0)
    const betCount = data.length

    return {
      totalAmount,
      betCount,
    }
  }

  const getUserActiveBets = async () => {
    if (!userData.value) return []

    const now = new Date().toISOString()

    const { data, error } = await supabase
      .from('bet_userdata')
      .select(`
        *,
        bet:Bets (
          *,
          prono:Pronos!inner (
            *,
            team:Teams (*)
          )
        )
      `)
      .eq('userdata_id', userData.value.id)
      .lte('bet.prono.start_at', now)
      .gte('bet.prono.end_at', now)
      .order('created_at', { ascending: false })

    if (error) throw error

    return data as UserBetWithDetails[]
  }

  const calculatePotentialWin = (amount: number, odds: number) => {
    return Math.floor(amount * odds)
  }

  const deleteBet = async (betUserDataId: string) => {
    if (!userData.value) throw new Error('User not authenticated')

    // Get bet details first to refund tokens
    const { data: betData, error: fetchError } = await supabase
      .from('bet_userdata')
      .select(`
        *,
        bet:Bets (
          prono:Pronos (
            team_id,
            start_at
          )
        )
      `)
      .eq('id', betUserDataId)
      .single()

    if (fetchError) throw fetchError

    // Check if prono hasn't started yet
    const startAt = new Date(betData.bet.prono.start_at)
    if (startAt <= new Date()) {
      throw new Error('Impossible de supprimer un pari après le début du pronostic')
    }

    const teamId = betData.bet.prono.team_id

    // Delete bet
    const { error: deleteError } = await supabase
      .from('bet_userdata')
      .delete()
      .eq('id', betUserDataId)

    if (deleteError) throw deleteError

    // Refund tokens
    if (teamId) {
      const currentTokens = await getUserTeamTokens(teamId)
      const { error: refundError } = await supabase
        .from('team_userdata')
        .update({ token: currentTokens + betData.amount })
        .eq('team_id', teamId)
        .eq('userdata_id', userData.value.id)

      if (refundError) throw refundError
    } else {
      const { error: refundError } = await supabase
        .from('UserDatas')
        .update({ tokens: userData.value.tokens + betData.amount })
        .eq('id', userData.value.id)

      if (refundError) throw refundError

      await refreshUserData()
    }

    return true
  }

  return {
    placeBet,
    getUserBets,
    getUserBetsByProno,
    getBetStats,
    getUserActiveBets,
    calculatePotentialWin,
    deleteBet,
  }
}


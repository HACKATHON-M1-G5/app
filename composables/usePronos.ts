import type { Prono, PronoWithBets, Bet } from '~/types/database'

export const usePronos = () => {
  const supabase = useSupabaseClient()
  const { userData } = useUserData()

  const createProno = async (pronoData: {
    name: string
    start_at: string
    end_at: string
    team_id: string | null
    event_id?: string | null
    bets: Array<{ title: string; odds: number }>
  }) => {
    if (!userData.value) throw new Error('User not authenticated')

    // Create prono
    const { data: prono, error: pronoError } = await supabase
      .from('Pronos')
      .insert({
        name: pronoData.name,
        start_at: pronoData.start_at,
        end_at: pronoData.end_at,
        team_id: pronoData.team_id,
        event_id: pronoData.event_id || null,
        owner_id: userData.value.id,
      })
      .select()
      .single()

    if (pronoError) throw pronoError

    // Create bets
    if (pronoData.bets.length > 0) {
      const betsToInsert = pronoData.bets.map(bet => ({
        prono_id: prono.id,
        title: bet.title,
        odds: bet.odds,
        result: null,
        option_id: null,
      }))

      const { error: betsError } = await supabase
        .from('Bets')
        .insert(betsToInsert)

      if (betsError) throw betsError
    }

    return prono as Prono
  }

  const getPronoById = async (pronoId: string) => {
    const { data, error } = await supabase
      .from('Pronos')
      .select(`
        *,
        owner:UserDatas (*),
        team:Teams (*),
        bets:Bets (*)
      `)
      .eq('id', pronoId)
      .single()

    if (error) throw error

    return data as PronoWithBets
  }

  const getPublicPronos = async () => {
    const { data, error } = await supabase
      .from('Pronos')
      .select(`
        *,
        owner:UserDatas (*),
        bets:Bets (*)
      `)
      .is('team_id', null)
      .order('created_at', { ascending: false })

    if (error) throw error

    return data as PronoWithBets[]
  }

  const getTeamPronos = async (teamId: string) => {
    const { data, error } = await supabase
      .from('Pronos')
      .select(`
        *,
        owner:UserDatas (*),
        team:Teams (*),
        bets:Bets (*)
      `)
      .eq('team_id', teamId)
      .order('created_at', { ascending: false })

    if (error) throw error

    return data as PronoWithBets[]
  }

  const getActivePronos = async () => {
    const now = new Date().toISOString()

    const { data, error } = await supabase
      .from('Pronos')
      .select(`
        *,
        owner:UserDatas (*),
        team:Teams (*),
        bets:Bets (*)
      `)
      .lte('start_at', now)
      .gte('end_at', now)
      .order('created_at', { ascending: false })

    if (error) throw error

    return data as PronoWithBets[]
  }

  const updateProno = async (
    pronoId: string,
    updates: Partial<Prono>
  ) => {
    const { error } = await supabase
      .from('Pronos')
      .update(updates)
      .eq('id', pronoId)

    if (error) throw error

    return true
  }

  const deleteProno = async (pronoId: string) => {
    const { error } = await supabase
      .from('Pronos')
      .delete()
      .eq('id', pronoId)

    if (error) throw error

    return true
  }

  const updateBetResult = async (betId: string, result: boolean) => {
    const { error } = await supabase
      .from('Bets')
      .update({ result })
      .eq('id', betId)

    if (error) throw error

    return true
  }

  const getBetsByPronoId = async (pronoId: string) => {
    const { data, error } = await supabase
      .from('Bets')
      .select('*')
      .eq('prono_id', pronoId)

    if (error) throw error

    return data as Bet[]
  }

  return {
    createProno,
    getPronoById,
    getPublicPronos,
    getTeamPronos,
    getActivePronos,
    updateProno,
    deleteProno,
    updateBetResult,
    getBetsByPronoId,
  }
}


import type { Team, TeamUserData, TeamWithMembers } from '~/types/database'

export const useTeams = () => {
  const supabase = useSupabaseClient()
  const { userData, whenUserDataReady } = useUserData()

  const ensureUser = async () => {
    const ud = await whenUserDataReady()
    if (!ud) throw new Error('User not authenticated')
    return ud
  }

  const generateJoinCode = () => {
    return Math.random().toString(36).substring(2, 10).toUpperCase()
  }

  const createTeam = async (teamData: {
    name: string
    description: string
    primary_color: string
    icon_url: string
    privacy: boolean
  }) => {
    const userData = await ensureUser()

    const joinCode = generateJoinCode()

    // Create team
    const { data: team, error: teamError } = await supabase
      .from('Teams')
      .insert({
        ...teamData,
        join_code: joinCode,
      })
      .select()
      .single()

    if (teamError) throw teamError

    // Add creator as owner
    const { error: memberError } = await supabase
      .from('team_userdata')
      .insert({
        team_id: team.id,
        userdata_id: userData.id,
        status: 'owner',
        joined_at: Date.now(),
        token: 1000,
      })

    if (memberError) throw memberError

    return team as Team
  }

  const getMyTeams = async () => {
    const me = await ensureUser()

    const { data, error } = await supabase
        .from('team_userdata')
        .select(`*, team:Teams (*)`)
        .eq('userdata_id', me.id)
        .in('status', ['member', 'owner'])

    if (error) throw error

    return (data ?? []).map((i: any) => i.team) as Team[]
  }

  const getPublicTeams = async () => {
    const { data, error } = await supabase
      .from('Teams')
      .select('*')
      .eq('privacy', false)
      .order('created_at', { ascending: false })

    if (error) throw error

    return data as Team[]
  }

  const getTeamById = async (teamId: string) => {
    const { data, error } = await supabase.from('Teams').select('*').eq('id', teamId).single()

    if (error) throw error

    return data as Team
  }

  const getTeamMembers = async (teamId: string) => {
    const { data, error } = await supabase
      .from('team_userdata')
      .select(
        `
        *,
        userdata:UserDatas (*)
      `
      )
      .eq('team_id', teamId)

    if (error) throw error

    return data as (TeamUserData & { userdata: any })[]
  }

  const joinTeam = async (teamId: string, joinCode?: string) => {
    const userData = await ensureUser()

    // Verify join code for private teams
    const team = await getTeamById(teamId)

    if (team.privacy && team.join_code !== joinCode) {
      throw new Error("Code d'invitation invalide")
    }

    const { error } = await supabase
      .from('team_userdata')
      .insert({
        team_id: teamId,
        userdata_id: userData.id,
        status: team.privacy ? 'pending' : 'member',
        joined_at: Date.now(),
        token: 1000,
      })

    if (error) throw error

    return true
  }

  const leaveTeam = async (teamId: string) => {
    const userData = await ensureUser()

    const { error } = await supabase
      .from('team_userdata')
      .delete()
      .eq('team_id', teamId)
      .eq('userdata_id', userData.id)

    if (error) throw error

    return true
  }

  const updateMemberStatus = async (
    teamId: string,
    userId: string,
    status: 'pending' | 'member' | 'banned' | 'owner'
  ) => {
    const { error } = await supabase
      .from('team_userdata')
      .update({ status })
      .eq('team_id', teamId)
      .eq('userdata_id', userId)

    if (error) throw error

    return true
  }

  const updateMemberTokens = async (teamId: string, userId: string, tokens: number) => {
    const { error } = await supabase
      .from('team_userdata')
      .update({ token: tokens })
      .eq('team_id', teamId)
      .eq('userdata_id', userId)

    if (error) throw error

    return true
  }

  const getTeamByJoinCode = async (joinCode: string) => {
    const { data, error } = await supabase
      .from('Teams')
      .select('*')
      .eq('join_code', joinCode)
      .single()

    if (error) throw error

    return data as Team
  }

  const isTeamOwner = async (teamId: string) => {
    try {
      const userData = await ensureUser()

      const { data, error } = await supabase
          .from('team_userdata')
          .select('status')
          .eq('team_id', teamId)
          .eq('userdata_id', userData.id)
          .single()

      if (error) return false

      return data.status === 'owner'
    } catch (e) {
        return false
    }
  }

  const getUserTeamTokens = async (teamId: string) => {
    try {
      const userData = await ensureUser()

      const { data, error } = await supabase
          .from('team_userdata')
          .select('token')
          .eq('team_id', teamId)
          .eq('userdata_id', userData.id)
          .single()

      if (error) return 0

      return data.token
    } catch (e) {
        return 0
    }
  }

  return {
    createTeam,
    getMyTeams,
    getPublicTeams,
    getTeamById,
    getTeamMembers,
    joinTeam,
    leaveTeam,
    updateMemberStatus,
    updateMemberTokens,
    getTeamByJoinCode,
    isTeamOwner,
    getUserTeamTokens,
  }
}

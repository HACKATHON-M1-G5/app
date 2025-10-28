import type { RealtimeChannel } from '@supabase/supabase-js'

export const useRealtime = () => {
  const supabase = useSupabaseClient()
  const channels = ref<Map<string, RealtimeChannel>>(new Map())

  /**
   * S'abonner aux changements d'une table
   */
  const subscribe = (
    tableName: string,
    callback: (payload: any) => void,
    filter?: { column: string; value: string | number }
  ) => {
    const channelName = filter
      ? `${tableName}:${filter.column}=${filter.value}`
      : tableName

    // Si un canal existe déjà, ne pas en créer un nouveau
    if (channels.value.has(channelName)) {
      console.log(`📡 Canal déjà actif: ${channelName}`)
      return channelName
    }

    console.log(`📡 Création canal realtime: ${channelName}`)

    let channel = supabase.channel(channelName)

    // Construire la souscription
    if (filter) {
      channel = channel.on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: tableName,
          filter: `${filter.column}=eq.${filter.value}`,
        },
        (payload) => {
          console.log(`🔔 Changement détecté sur ${tableName}:`, payload)
          callback(payload)
        }
      )
    } else {
      channel = channel.on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: tableName,
        },
        (payload) => {
          console.log(`🔔 Changement détecté sur ${tableName}:`, payload)
          callback(payload)
        }
      )
    }

    channel.subscribe((status) => {
      console.log(`📡 Status du canal ${channelName}:`, status)
    })

    channels.value.set(channelName, channel)
    return channelName
  }

  /**
   * Se désabonner d'un canal spécifique
   */
  const unsubscribe = (channelName: string) => {
    const channel = channels.value.get(channelName)
    if (channel) {
      console.log(`📡 Désinscription du canal: ${channelName}`)
      supabase.removeChannel(channel)
      channels.value.delete(channelName)
    }
  }

  /**
   * Se désabonner de tous les canaux
   */
  const unsubscribeAll = () => {
    console.log(`📡 Désinscription de tous les canaux (${channels.value.size})`)
    channels.value.forEach((channel, name) => {
      supabase.removeChannel(channel)
    })
    channels.value.clear()
  }

  /**
   * S'abonner aux paris d'un prono
   */
  const subscribeToPronoBets = (pronoId: string, callback: () => void) => {
    // S'abonner aux changements des Bets du prono
    const betsChannel = subscribe(
      'Bets',
      () => callback(),
      { column: 'prono_id', value: pronoId }
    )

    // S'abonner aux paris des utilisateurs (bet_userdata) liés au prono
    // Note: On écoute tous les bet_userdata et on filtre côté client
    const betUserdataChannel = subscribe('bet_userdata', () => callback())

    return [betsChannel, betUserdataChannel]
  }

  /**
   * S'abonner aux pronos d'un groupe
   */
  const subscribeToTeamPronos = (teamId: string, callback: () => void) => {
    return subscribe('Pronos', () => callback(), { column: 'team_id', value: teamId })
  }

  /**
   * S'abonner aux membres d'un groupe
   */
  const subscribeToTeamMembers = (teamId: string, callback: () => void) => {
    return subscribe('team_userdata', () => callback(), { column: 'team_id', value: teamId })
  }

  /**
   * S'abonner aux données d'un utilisateur
   */
  const subscribeToUserData = (userId: string, callback: () => void) => {
    return subscribe('UserDatas', () => callback(), { column: 'id', value: userId })
  }

  /**
   * S'abonner à tous les pronos publics
   */
  const subscribeToPublicPronos = (callback: () => void) => {
    return subscribe('Pronos', () => callback())
  }

  /**
   * S'abonner à tous les groupes
   */
  const subscribeToTeams = (callback: () => void) => {
    return subscribe('Teams', () => callback())
  }

  return {
    subscribe,
    unsubscribe,
    unsubscribeAll,
    subscribeToPronoBets,
    subscribeToTeamPronos,
    subscribeToTeamMembers,
    subscribeToUserData,
    subscribeToPublicPronos,
    subscribeToTeams,
  }
}


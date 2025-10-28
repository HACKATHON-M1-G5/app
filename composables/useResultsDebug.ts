/**
 * Version de debug pour tester manuellement la distribution
 * Utilisez cette fonction dans la console du navigateur
 */
export const useResultsDebug = () => {
  const supabase = useSupabaseClient()

  /**
   * Tester manuellement la distribution pour un bet
   * À appeler depuis la console : 
   * const { testDistribution } = useResultsDebug(); testDistribution('bet-id')
   */
  const testDistribution = async (betId: string) => {
    console.log('🔧 === DÉBUT DU TEST DE DISTRIBUTION ===')
    console.log('📍 Bet ID:', betId)

    try {
      // 1. Récupérer le bet
      console.log('📡 Étape 1: Récupération du bet...')
      const { data: bet, error: betError } = await supabase
        .from('Bets')
        .select(`
          *,
          prono:Pronos (
            *
          )
        `)
        .eq('id', betId)
        .single()

      if (betError) {
        console.error('❌ ERREUR récupération bet:', betError)
        return { success: false, error: betError }
      }

      console.log('✅ Bet récupéré:', bet)

      // 2. Récupérer les paris
      console.log('📡 Étape 2: Récupération des paris sur ce bet...')
      const { data: userBets, error: userBetsError } = await supabase
        .from('bet_userdata')
        .select('*')
        .eq('bet_id', betId)

      if (userBetsError) {
        console.error('❌ ERREUR récupération paris:', userBetsError)
        return { success: false, error: userBetsError }
      }

      console.log(`✅ ${userBets?.length || 0} pari(s) trouvé(s):`, userBets)

      if (!userBets || userBets.length === 0) {
        console.log('⚠️ Aucun pari à distribuer')
        return { success: true, message: 'Aucun pari' }
      }

      // 3. Tester la distribution pour chaque parieur
      const isGroupProno = bet.prono && bet.prono.team_id !== null
      console.log(`🎲 Type: ${isGroupProno ? 'Groupe' : 'Public'}`)

      const results = []

      for (const userBet of userBets) {
        console.log(`\n👤 === Traitement utilisateur ${userBet.userdata_id} ===`)
        const winAmount = Math.floor(userBet.amount * bet.odds)
        console.log(`💰 Calcul: ${userBet.amount} × ${bet.odds} = ${winAmount} tokens`)

        if (isGroupProno) {
          console.log(`🏆 Mode Groupe (team_id: ${bet.prono.team_id})`)
          
          // Récupérer tokens actuels
          const { data: currentMembership, error: fetchError } = await supabase
            .from('team_userdata')
            .select('token')
            .eq('team_id', bet.prono.team_id)
            .eq('userdata_id', userBet.userdata_id)
            .single()

          if (fetchError) {
            console.error('❌ ERREUR fetch tokens groupe:', fetchError)
            results.push({ userId: userBet.userdata_id, success: false, error: fetchError })
            continue
          }

          console.log(`📊 Tokens groupe avant: ${currentMembership.token}`)
          console.log(`📊 Tokens groupe après: ${currentMembership.token + winAmount}`)

          // Mettre à jour
          const { data: updateData, error: updateError } = await supabase
            .from('team_userdata')
            .update({ token: currentMembership.token + winAmount })
            .eq('team_id', bet.prono.team_id)
            .eq('userdata_id', userBet.userdata_id)
            .select()

          if (updateError) {
            console.error('❌ ERREUR update tokens groupe:', updateError)
            results.push({ userId: userBet.userdata_id, success: false, error: updateError })
          } else {
            console.log('✅ UPDATE RÉUSSI (groupe):', updateData)
            results.push({ userId: userBet.userdata_id, success: true, newTokens: currentMembership.token + winAmount })
          }

        } else {
          console.log(`🌍 Mode Public`)
          
          // Récupérer tokens actuels
          const { data: currentUser, error: fetchError } = await supabase
            .from('UserDatas')
            .select('tokens')
            .eq('id', userBet.userdata_id)
            .single()

          if (fetchError) {
            console.error('❌ ERREUR fetch tokens publics:', fetchError)
            results.push({ userId: userBet.userdata_id, success: false, error: fetchError })
            continue
          }

          console.log(`📊 Tokens publics avant: ${currentUser.tokens}`)
          console.log(`📊 Tokens publics après: ${currentUser.tokens + winAmount}`)

          // Mettre à jour
          const { data: updateData, error: updateError } = await supabase
            .from('UserDatas')
            .update({ tokens: currentUser.tokens + winAmount })
            .eq('id', userBet.userdata_id)
            .select()

          if (updateError) {
            console.error('❌ ERREUR update tokens publics:', updateError)
            results.push({ userId: userBet.userdata_id, success: false, error: updateError })
          } else {
            console.log('✅ UPDATE RÉUSSI (public):', updateData)
            results.push({ userId: userBet.userdata_id, success: true, newTokens: currentUser.tokens + winAmount })
          }
        }
      }

      console.log('\n🎉 === FIN DU TEST ===')
      console.log('📊 Résumé:', results)
      
      return { success: true, results }

    } catch (error) {
      console.error('💥 ERREUR GLOBALE:', error)
      return { success: false, error }
    }
  }

  /**
   * Vérifier manuellement les tokens d'un utilisateur
   */
  const checkUserTokens = async (userId: string) => {
    console.log('🔍 Vérification tokens pour:', userId)
    
    const { data, error } = await supabase
      .from('UserDatas')
      .select('tokens, username')
      .eq('id', userId)
      .single()

    if (error) {
      console.error('❌ Erreur:', error)
    } else {
      console.log('✅ Tokens:', data)
    }

    return data
  }

  /**
   * Lister tous les paris sur un bet
   */
  const listBetsOnBet = async (betId: string) => {
    console.log('🔍 Liste des paris sur le bet:', betId)
    
    const { data, error } = await supabase
      .from('bet_userdata')
      .select(`
        *,
        userdata:UserDatas(username)
      `)
      .eq('bet_id', betId)

    if (error) {
      console.error('❌ Erreur:', error)
    } else {
      console.log('✅ Paris:', data)
    }

    return data
  }

  return {
    testDistribution,
    checkUserTokens,
    listBetsOnBet,
  }
}



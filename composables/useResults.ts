import type { Bet } from '~/types/database'

export const useResults = () => {
  const supabase = useSupabaseClient()

  /**
   * Distribuer les gains pour un bet gagnant
   */
  const distributeWinnings = async (betId: string) => {
    console.log(`🎯 Début de la distribution pour le bet ${betId}`)
    
    // 1. Récupérer le bet avec ses informations
    const { data: bet, error: betError } = await supabase
      .from('Bets')
      .select(`
        *,
        prono:Pronos (
          team_id
        )
      `)
      .eq('id', betId)
      .single()

    if (betError) {
      console.error('❌ Erreur lors de la récupération du bet:', betError)
      throw betError
    }

    console.log('📊 Bet récupéré:', { betId, odds: bet.odds, prono: bet.prono })

    // 2. Récupérer tous les paris sur ce bet
    const { data: userBets, error: userBetsError } = await supabase
      .from('bet_userdata')
      .select('*')
      .eq('bet_id', betId)

    if (userBetsError) {
      console.error('❌ Erreur lors de la récupération des paris:', userBetsError)
      throw userBetsError
    }

    if (!userBets || userBets.length === 0) {
      console.log('ℹ️ Aucun pari à traiter pour ce bet')
      return
    }

    console.log(`💰 ${userBets.length} pari(s) à traiter`)

    // 3. Distribuer les gains selon le type de prono (groupe ou public)
    const isGroupProno = bet.prono && bet.prono.team_id !== null
    console.log(`🎲 Type de prono: ${isGroupProno ? 'Groupe' : 'Public'}`, { team_id: bet.prono?.team_id })

    for (const userBet of userBets) {
      const winAmount = Math.floor(userBet.amount * bet.odds)
      console.log(`👤 Utilisateur ${userBet.userdata_id}: ${userBet.amount} tokens × ${bet.odds} = ${winAmount} tokens`)

      if (isGroupProno) {
        // Paris de groupe : créditer les tokens du groupe
        console.log(`🏆 Distribution groupe (team_id: ${bet.prono.team_id})`)
        
        // Utiliser une fonction PostgreSQL pour incrémenter directement
        const { data: updateData, error: updateError } = await supabase.rpc(
          'increment_team_tokens',
          { 
            p_team_id: bet.prono.team_id, 
            p_user_id: userBet.userdata_id, 
            amount_to_add: winAmount 
          }
        )

        if (updateError) {
          console.error('❌ Erreur lors de la distribution des gains (groupe):', updateError)
          console.log('🔄 Tentative alternative avec SELECT + UPDATE...')
          
          // Méthode alternative si la fonction RPC n'existe pas
          const { data: currentMembership, error: fetchError } = await supabase
            .from('team_userdata')
            .select('token')
            .eq('team_id', bet.prono.team_id)
            .eq('userdata_id', userBet.userdata_id)
            .single()

          if (fetchError) {
            console.error('❌ Erreur lors de la récupération des tokens du groupe:', fetchError)
            continue
          }

          console.log(`📊 Tokens actuels du groupe: ${currentMembership.token} → ${currentMembership.token + winAmount}`)

          const { error: updateError2 } = await supabase
            .from('team_userdata')
            .update({ 
              token: currentMembership.token + winAmount 
            })
            .eq('team_id', bet.prono.team_id)
            .eq('userdata_id', userBet.userdata_id)

          if (updateError2) {
            console.error('❌ Erreur lors de la distribution des gains (groupe) - méthode 2:', updateError2)
          } else {
            console.log('✅ Gains distribués avec succès (groupe) - méthode 2')
          }
        } else {
          console.log('✅ Gains distribués avec succès (groupe) via RPC:', updateData)
        }
      } else {
        // Paris public : créditer les tokens globaux
        console.log(`🌍 Distribution publique`)
        
        // Utiliser une fonction PostgreSQL pour incrémenter directement
        const { data: updateData, error: updateError } = await supabase.rpc(
          'increment_user_tokens',
          { user_id: userBet.userdata_id, amount_to_add: winAmount }
        )

        if (updateError) {
          console.error('❌ Erreur lors de la distribution des gains (public):', updateError)
          console.log('🔄 Tentative alternative avec SELECT + UPDATE...')
          
          // Méthode alternative si la fonction RPC n'existe pas
          const { data: currentUser, error: fetchError } = await supabase
            .from('UserDatas')
            .select('tokens')
            .eq('id', userBet.userdata_id)
            .single()

          if (fetchError) {
            console.error('❌ Erreur lors de la récupération des tokens:', fetchError)
            continue
          }

          console.log(`📊 Tokens actuels: ${currentUser.tokens} → ${currentUser.tokens + winAmount}`)

          const { error: updateError2 } = await supabase
            .from('UserDatas')
            .update({ 
              tokens: currentUser.tokens + winAmount 
            })
            .eq('id', userBet.userdata_id)

          if (updateError2) {
            console.error('❌ Erreur lors de la distribution des gains (public) - méthode 2:', updateError2)
          } else {
            console.log('✅ Gains distribués avec succès (public) - méthode 2')
          }
        } else {
          console.log('✅ Gains distribués avec succès (public) via RPC:', updateData)
        }
      }
    }

    console.log(`✨ Distribution terminée pour ${userBets.length} pari(s) sur le bet ${betId}`)
  }

  /**
   * Définir le résultat d'un bet et distribuer les gains si gagnant
   */
  const setResultAndDistribute = async (betId: string, result: boolean) => {
    console.log(`🎯 setResultAndDistribute - Bet: ${betId}, Résultat: ${result ? 'GAGNANT ✅' : 'PERDANT ❌'}`)
    
    // 1. Mettre à jour le résultat
    const { error: updateError } = await supabase
      .from('Bets')
      .update({ result })
      .eq('id', betId)

    if (updateError) {
      console.error('❌ Erreur lors de la mise à jour du résultat:', updateError)
      throw updateError
    }

    console.log('✅ Résultat mis à jour dans la base de données')

    // 2. Si c'est un résultat gagnant, distribuer les gains
    if (result === true) {
      console.log('🎁 Lancement de la distribution des gains...')
      await distributeWinnings(betId)
    } else {
      console.log('ℹ️ Pas de distribution (résultat perdant)')
    }

    return true
  }

  /**
   * Vérifier si un prono a au moins un résultat défini
   */
  const pronoHasResults = async (pronoId: string) => {
    const { data, error } = await supabase
      .from('Bets')
      .select('result')
      .eq('prono_id', pronoId)
      .not('result', 'is', null)
      .limit(1)

    if (error) throw error

    return data && data.length > 0
  }

  /**
   * Vérifier si tous les résultats d'un prono sont définis
   */
  const pronoAllResultsDefined = async (pronoId: string) => {
    const { data: allBets, error: allError } = await supabase
      .from('Bets')
      .select('result')
      .eq('prono_id', pronoId)

    if (allError) throw allError

    if (!allBets || allBets.length === 0) return false

    return allBets.every(bet => bet.result !== null)
  }

  return {
    distributeWinnings,
    setResultAndDistribute,
    pronoHasResults,
    pronoAllResultsDefined,
  }
}


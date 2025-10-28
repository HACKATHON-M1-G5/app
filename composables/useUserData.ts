// useUserData.ts
import type { UserData } from '~/types/database'

export const useUserData = () => {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()
  const userData = useState<UserData | null>('userData', () => null)
  const loading = useState<boolean>('userDataLoading', () => false)
  const errorMsg = useState<string | null>('userDataError', () => null)

  const fetchUserData = async () => {
    if (!user.value) {
      userData.value = null
      return
    }
    loading.value = true
    errorMsg.value = null
    try {
      const { data, error } = await supabase
          .from('UserDatas')
          .select('*')
          .eq('auth_id', user.value.id)
          .single()
      if (error) throw error
      userData.value = data as UserData
    } catch (e: any) {
      console.error('Error fetching user data:', e)
      errorMsg.value = e?.message ?? 'Unknown error'
      userData.value = null
    } finally {
      loading.value = false
    }
  }

  const whenUserDataReady = async (): Promise<UserData | null> => {
    if (userData.value || !loading.value) {
      // soit déjà là, soit on a déjà tenté
      return userData.value
    }
    await new Promise<void>((resolve) => {
      const stop = watch(
          [userData, loading],
          () => {
            if (userData.value || !loading.value) {
              stop()
              resolve()
            }
          },
          { immediate: true },
      )
    })
    return userData.value
  }

  const refreshUserData = async () => {
    await fetchUserData()
  }

  watch(
      user,
      async (newUser) => {
        if (newUser) await fetchUserData()
        else userData.value = null
      },
      { immediate: true },
  )

  return { userData, loading, errorMsg, refreshUserData, whenUserDataReady }
}

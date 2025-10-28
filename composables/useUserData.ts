import type { UserData } from '~/types/database'

export const useUserData = () => {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()
  const userData = useState<UserData | null>('userData', () => null)
  const loading = useState<boolean>('userDataLoading', () => false)

  const fetchUserData = async () => {
    if (!user.value) {
      userData.value = null
      return
    }

    loading.value = true

    try {
      const { data, error } = await supabase
        .from('UserDatas')
        .select('*')
        .eq('auth_id', user.value.id)
        .single()

      if (error) throw error

      userData.value = data as UserData
    } catch (e) {
      console.error('Error fetching user data:', e)
      userData.value = null
    } finally {
      loading.value = false
    }
  }

  const refreshUserData = async () => {
    await fetchUserData()
  }

  // Auto-fetch when user changes
  watch(
    user,
    (newUser) => {
      if (newUser) {
        fetchUserData()
      } else {
        userData.value = null
      }
    },
    { immediate: true }
  )

  return {
    userData,
    loading,
    refreshUserData,
  }
}

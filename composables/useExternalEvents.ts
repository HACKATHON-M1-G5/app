import type { ExternalEvent, ExternalOption } from './useExternalApi'

export const useExternalEvents = () => {
  const { request } = useExternalApi()

  const searchEvents = async (query: string) => {
    // proxy through Nuxt server to avoid CORS
    const data = await $fetch('/api/external/events')
    return (data as any[]) as ExternalEvent[]
  }

  const getEventOptions = async (eventId: string) => {
    // proxy through Nuxt server to avoid CORS
    const data = await $fetch(`/api/external/event-${eventId}`)
    return (data as any[]) as ExternalOption[]
  }

  return { searchEvents, getEventOptions }
}



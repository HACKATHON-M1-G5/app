import type { ExternalEvent, ExternalOption } from './useExternalApi'

export const useExternalEvents = () => {
  const { request } = useExternalApi()

  const searchEvents = async (query: string = '') => {
    // proxy through Nuxt server to avoid CORS
    const data = await $fetch('/api/external/events')
    const events = (data as any[]) as ExternalEvent[]
    
    // Filtrer les événements par nom si une query est fournie
    if (query.trim()) {
      const lowerQuery = query.toLowerCase()
      return events.filter(event => 
        event.name.toLowerCase().includes(lowerQuery)
      )
    }
    
    return events
  }

  const getEvent = async (eventId: string | number) => {
    // Récupère un événement spécifique
    const data = await $fetch(`/api/external/event/${eventId}`)
    return data as ExternalEvent
  }

  const getAllOptions = async () => {
    // Récupère toutes les options disponibles
    const data = await $fetch('/api/external/options')
    return (data as any[]) as ExternalOption[]
  }

  const getEventOptions = async (eventId: string | number) => {
    // Pour l'instant, retourne toutes les options
    // Note: L'API Django ne semble pas avoir d'endpoint pour récupérer les options d'un événement spécifique
    // Vous devrez peut-être ajuster cela selon la structure réelle de votre API
    const options = await getAllOptions()
    
    // Si l'API retourne des options avec un event_id, filtrer ici
    // Pour l'instant on retourne toutes les options
    return options
  }

  return { searchEvents, getEvent, getAllOptions, getEventOptions }
}



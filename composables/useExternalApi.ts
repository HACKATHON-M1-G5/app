export const useExternalApi = () => {
  const BASE = 'https://api-django-external.onrender.com/api'

  const request = async (path: string, init?: RequestInit) => {
    const url = `${BASE}${path}`
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
      ...(init?.headers || {}),
    }

    const res = await fetch(url, { ...init, headers })
    if (!res.ok) {
      let message = 'External API error'
      try {
        message = await res.text()
      } catch {}
      throw new Error(message)
    }
    return res.status === 204 ? null : res.json()
  }

  return { request }
}

export type ExternalCategory = {
  id: number
  name: string
  description: string
  created_at: string
  updated_at: string
}

export type ExternalEvent = {
  id: number
  name: string
  start_at: string
  end_at_expected: string
  end_at_actual: string | null
  status: 'pending' | 'ongoing' | 'completed' | 'cancelled'
  score: number | null
  category: number
}

export type ExternalOption = {
  id: number
  name: string
  description?: string
}



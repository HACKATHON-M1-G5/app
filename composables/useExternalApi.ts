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

export type ExternalEvent = {
  id: string
  name: string
  starts_at?: string
}

export type ExternalOption = {
  id: string
  label: string
}



export default defineEventHandler(async (event) => {
  const id = getRouterParam(event, 'id')
  const url = `https://api-django-external.onrender.com/api/event/event/${id}/`
  const res = await fetch(url, { method: 'GET' })
  if (!res.ok) {
    const text = await res.text().catch(() => 'Upstream error')
    throw createError({ statusCode: res.status, statusMessage: text })
  }
  const data = await res.json()
  return data
})


export const getPagination = (pageStr, limitStr, maxLimit = 50) => {
  const page = parseInt(pageStr, 10) || 1
  const limit = Math.min(parseInt(limitStr, 10) || 20, maxLimit)

  const from = (page - 1) * limit
  const to = from + limit - 1

  return { page, limit, from, to }
}

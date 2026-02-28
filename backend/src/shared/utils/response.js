export const success = (res, data, status = 200) => {
  res.status(status).json(data)
}

export const fail = (res, code, message, status = 400) => {
  res.status(status).json({ error: { code, message } })
}

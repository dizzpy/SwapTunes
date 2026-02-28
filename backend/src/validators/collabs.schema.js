import { z } from 'zod'

export const collabSchema = z.object({
  title: z.string().min(5, 'Title must be at least 5 characters'),
  description: z.string().min(10, 'Description must be at least 10 characters'),
  looking_for: z.array(z.string()).min(1, 'Must select at least 1 role'),
  genre_style: z.array(z.string()).optional(),
  payment_type: z.enum(['paid', 'revenue_share', 'free']),
  status: z.enum(['open', 'closed']).default('open')
})

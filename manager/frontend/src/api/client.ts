import axios from 'axios'

const api = axios.create({
  baseURL: '/api',
  timeout: 10000
})

// 印章 API
export const stampApi = {
  calibrate: (data: { name: string; points: [number, number][]; description?: string }) =>
    api.post('/admin/stamps/calibrate', data),
  list: () => api.get('/admin/stamps'),
  get: (id: number) => api.get(`/admin/stamps/${id}`),
  delete: (id: number) => api.delete(`/admin/stamps/${id}`)
}

// 客戶 API
export const clientApi = {
  create: (data: { name: string }) => api.post('/admin/clients', data),
  list: () => api.get('/admin/clients'),
  get: (id: number) => api.get(`/admin/clients/${id}`),
  toggleStatus: (id: number) => api.put(`/admin/clients/${id}/toggle`)
}

// 權限 API
export const permissionApi = {
  create: (data: { client_id: number; stamp_id: number }) =>
    api.post('/admin/permissions', data),
  list: (params?: { client_id?: number; stamp_id?: number }) =>
    api.get('/admin/permissions', { params }),
  delete: (id: number) => api.delete(`/admin/permissions/${id}`)
}


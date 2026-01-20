import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api'

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Add request interceptor for auth headers
api.interceptors.request.use((config) => {
  // Add user ID header if needed (for authorized operations)
  const userId = localStorage.getItem('userId') || 'admin'
  if (userId) {
    config.headers['X-User-ID'] = userId
  }
  return config
})

// Land record operations
export const searchLandRecord = async (plotId) => {
  const response = await api.get(`/land/${plotId}`)
  return response.data
}

export const getLandRecord = async (plotId) => {
  const response = await api.get(`/land/${plotId}`)
  return response.data
}

export const getLandHistory = async (plotId) => {
  const response = await api.get(`/land/${plotId}/history`)
  return response.data
}

export const getAllLandRecords = async () => {
  const response = await api.get('/land')
  return response.data
}

export const createLandRecord = async (data) => {
  const response = await api.post('/land/create', data)
  return response.data
}

export const transferLand = async (data) => {
  const response = await api.post('/land/transfer', data)
  return response.data
}

export const updateLandStatus = async ({ plotId, status }) => {
  const response = await api.put(`/land/${plotId}/status`, { status })
  return response.data
}

// Health check
export const checkHealth = async () => {
  const response = await api.get('/health')
  return response.data
}

export default api

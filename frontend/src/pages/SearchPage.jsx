import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Search, AlertCircle, Loader } from 'lucide-react'
import { searchLandRecord } from '../services/api'

export default function SearchPage() {
  const [plotId, setPlotId] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const navigate = useNavigate()

  const handleSearch = async (e) => {
    e.preventDefault()
    if (!plotId.trim()) {
      setError('Please enter a Plot ID')
      return
    }

    setLoading(true)
    setError('')

    try {
      const result = await searchLandRecord(plotId.trim())
      if (result.success) {
        navigate(`/record/${plotId.trim()}`)
      }
    } catch (err) {
      setError(err.response?.data?.error?.message || err.message || 'Failed to search land record')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-2xl mx-auto">
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Search Land Records</h1>
        <p className="text-gray-600">Enter a Plot ID to view land ownership information</p>
      </div>

      <div className="card">
        <form onSubmit={handleSearch} className="space-y-4">
          <div>
            <label htmlFor="plotId" className="block text-sm font-medium text-gray-700 mb-2">
              Plot ID
            </label>
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                id="plotId"
                type="text"
                value={plotId}
                onChange={(e) => setPlotId(e.target.value.toUpperCase())}
                placeholder="Enter Plot ID (e.g., PLOT001)"
                className="input-field pl-10"
                disabled={loading}
              />
            </div>
          </div>

          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start gap-3">
              <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
              <p className="text-sm text-red-800">{error}</p>
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="btn-primary w-full flex items-center justify-center"
          >
            {loading ? (
              <>
                <Loader className="w-5 h-5 mr-2 animate-spin" />
                Searching...
              </>
            ) : (
              <>
                <Search className="w-5 h-5 mr-2" />
                Search
              </>
            )}
          </button>
        </form>
      </div>

      <div className="mt-8 card bg-primary-50 border-primary-200">
        <h3 className="font-semibold text-primary-900 mb-2">Need Help?</h3>
        <p className="text-sm text-primary-800">
          Enter the Plot ID exactly as it appears in the land registry. Plot IDs are case-sensitive.
        </p>
      </div>
    </div>
  )
}

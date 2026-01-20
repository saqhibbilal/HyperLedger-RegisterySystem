import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { Loader, AlertCircle, Clock, User, MapPin, Ruler, FileText, History } from 'lucide-react'
import { getLandRecord, getLandHistory } from '../services/api'

export default function RecordPage() {
  const { plotId } = useParams()
  const [record, setRecord] = useState(null)
  const [history, setHistory] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [activeTab, setActiveTab] = useState('details')

  useEffect(() => {
    loadRecord()
  }, [plotId])

  const loadRecord = async () => {
    setLoading(true)
    setError('')
    try {
      const recordResult = await getLandRecord(plotId)
      if (recordResult.success) {
        setRecord(recordResult.data)
        // Load history
        try {
          const historyResult = await getLandHistory(plotId)
          if (historyResult.success) {
            setHistory(historyResult.data || [])
          }
        } catch (err) {
          console.error('Failed to load history:', err)
        }
      }
    } catch (err) {
      setError(err.response?.data?.error?.message || err.message || 'Failed to load land record')
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="flex justify-center items-center py-20">
        <Loader className="w-8 h-8 text-primary-600 animate-spin" />
      </div>
    )
  }

  if (error || !record) {
    return (
      <div className="max-w-2xl mx-auto">
        <div className="card border-red-200 bg-red-50">
          <div className="flex items-start gap-3">
            <AlertCircle className="w-6 h-6 text-red-600 flex-shrink-0" />
            <div>
              <h3 className="font-semibold text-red-900 mb-1">Error</h3>
              <p className="text-red-800 mb-4">{error || 'Land record not found'}</p>
              <Link to="/search" className="btn-secondary text-sm">
                Back to Search
              </Link>
            </div>
          </div>
        </div>
      </div>
    )
  }

  const getStatusColor = (status) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800 border-green-200'
      case 'pending':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200'
      case 'disputed':
        return 'bg-red-100 text-red-800 border-red-200'
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200'
    }
  }

  return (
    <div className="max-w-5xl mx-auto">
      {/* Header */}
      <div className="mb-6">
        <Link to="/search" className="text-primary-600 hover:text-primary-700 text-sm font-medium mb-4 inline-block">
          ← Back to Search
        </Link>
        <h1 className="text-3xl font-bold text-gray-900">Land Record: {plotId}</h1>
      </div>

      {/* Status Badge */}
      <div className="mb-6">
        <span className={`inline-block px-4 py-2 rounded-full text-sm font-medium border ${getStatusColor(record.status)}`}>
          {record.status.toUpperCase()}
        </span>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200 mb-6">
        <div className="flex space-x-8">
          <button
            onClick={() => setActiveTab('details')}
            className={`pb-4 px-1 font-medium transition-colors ${
              activeTab === 'details'
                ? 'text-primary-600 border-b-2 border-primary-600'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            <FileText className="w-4 h-4 inline-block mr-2" />
            Details
          </button>
          <button
            onClick={() => setActiveTab('history')}
            className={`pb-4 px-1 font-medium transition-colors ${
              activeTab === 'history'
                ? 'text-primary-600 border-b-2 border-primary-600'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            <History className="w-4 h-4 inline-block mr-2" />
            History ({history.length})
          </button>
        </div>
      </div>

      {/* Details Tab */}
      {activeTab === 'details' && (
        <div className="grid md:grid-cols-2 gap-6">
          <div className="card">
            <div className="card-header">
              <h2 className="text-xl font-semibold text-gray-900">Ownership Information</h2>
            </div>
            <div className="space-y-4">
              <InfoRow icon={<User />} label="Owner ID" value={record.ownerId} />
              <InfoRow icon={<User />} label="Owner Name" value={record.ownerName} />
              {record.previousOwnerID && (
                <InfoRow icon={<User />} label="Previous Owner" value={record.previousOwnerID} />
              )}
            </div>
          </div>

          <div className="card">
            <div className="card-header">
              <h2 className="text-xl font-semibold text-gray-900">Land Information</h2>
            </div>
            <div className="space-y-4">
              <InfoRow icon={<Ruler />} label="Area" value={`${record.area} sq. units`} />
              <InfoRow icon={<MapPin />} label="Location" value={record.location} />
              <InfoRow icon={<Clock />} label="Last Updated" value={new Date(record.timestamp).toLocaleString()} />
            </div>
          </div>
        </div>
      )}

      {/* History Tab */}
      {activeTab === 'history' && (
        <div className="card">
          {history.length > 0 ? (
            <div className="space-y-4">
              {history.map((transfer, index) => (
                <div
                  key={transfer.transferId || index}
                  className="border-l-4 border-primary-500 pl-4 py-2"
                >
                  <div className="flex justify-between items-start mb-2">
                    <div>
                      <p className="font-semibold text-gray-900">
                        Transfer from {transfer.fromOwnerId} to {transfer.toOwnerName}
                      </p>
                      <p className="text-sm text-gray-600">
                        {new Date(transfer.timestamp).toLocaleString()}
                      </p>
                    </div>
                    <span className="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">
                      {transfer.transactionId?.substring(0, 8)}...
                    </span>
                  </div>
                  {transfer.authorizedBy && (
                    <p className="text-sm text-gray-600">Authorized by: {transfer.authorizedBy}</p>
                  )}
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-12 text-gray-500">
              <History className="w-12 h-12 mx-auto mb-4 text-gray-400" />
              <p>No transfer history available</p>
            </div>
          )}
        </div>
      )}
    </div>
  )
}

function InfoRow({ icon, label, value }) {
  return (
    <div className="flex items-start gap-3">
      <div className="text-gray-400 mt-1">{icon}</div>
      <div className="flex-1">
        <p className="text-sm font-medium text-gray-500">{label}</p>
        <p className="text-gray-900 mt-1">{value}</p>
      </div>
    </div>
  )
}

import { useState } from 'react'
import { Plus, ArrowRightLeft, FileCheck, AlertCircle, CheckCircle } from 'lucide-react'
import { createLandRecord, transferLand, updateLandStatus } from '../services/api'

export default function AdminPage() {
  const [activeForm, setActiveForm] = useState('create')
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState({ type: '', text: '' })

  const showMessage = (type, text) => {
    setMessage({ type, text })
    setTimeout(() => setMessage({ type: '', text: '' }), 5000)
  }

  const handleCreate = async (data) => {
    setLoading(true)
    try {
      const result = await createLandRecord(data)
      if (result.success) {
        showMessage('success', 'Land record created successfully!')
        return true
      }
    } catch (err) {
      showMessage('error', err.response?.data?.error?.message || 'Failed to create land record')
      return false
    } finally {
      setLoading(false)
    }
  }

  const handleTransfer = async (data) => {
    setLoading(true)
    try {
      const result = await transferLand(data)
      if (result.success) {
        showMessage('success', 'Land ownership transferred successfully!')
        return true
      }
    } catch (err) {
      showMessage('error', err.response?.data?.error?.message || 'Failed to transfer land')
      return false
    } finally {
      setLoading(false)
    }
  }

  const handleStatusUpdate = async (data) => {
    setLoading(true)
    try {
      const result = await updateLandStatus(data)
      if (result.success) {
        showMessage('success', 'Land status updated successfully!')
        return true
      }
    } catch (err) {
      showMessage('error', err.response?.data?.error?.message || 'Failed to update status')
      return false
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-4xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Admin Portal</h1>
        <p className="text-gray-600">Manage land records (Authorized users only)</p>
      </div>

      {message.text && (
        <div className={`mb-6 p-4 rounded-lg flex items-start gap-3 ${
          message.type === 'success'
            ? 'bg-green-50 border border-green-200'
            : 'bg-red-50 border border-red-200'
        }`}>
          {message.type === 'success' ? (
            <CheckCircle className="w-5 h-5 text-green-600 flex-shrink-0" />
          ) : (
            <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0" />
          )}
          <p className={message.type === 'success' ? 'text-green-800' : 'text-red-800'}>
            {message.text}
          </p>
        </div>
      )}

      {/* Form Tabs */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        <FormTab
          icon={<Plus />}
          title="Create Record"
          active={activeForm === 'create'}
          onClick={() => setActiveForm('create')}
        />
        <FormTab
          icon={<ArrowRightLeft />}
          title="Transfer"
          active={activeForm === 'transfer'}
          onClick={() => setActiveForm('transfer')}
        />
        <FormTab
          icon={<FileCheck />}
          title="Update Status"
          active={activeForm === 'status'}
          onClick={() => setActiveForm('status')}
        />
      </div>

      {/* Forms */}
      <div className="card">
        {activeForm === 'create' && (
          <CreateForm onSubmit={handleCreate} loading={loading} />
        )}
        {activeForm === 'transfer' && (
          <TransferForm onSubmit={handleTransfer} loading={loading} />
        )}
        {activeForm === 'status' && (
          <StatusForm onSubmit={handleStatusUpdate} loading={loading} />
        )}
      </div>
    </div>
  )
}

function FormTab({ icon, title, active, onClick }) {
  return (
    <button
      onClick={onClick}
      className={`card text-center transition-all ${
        active
          ? 'border-primary-500 bg-primary-50'
          : 'hover:border-gray-300'
      }`}
    >
      <div className="flex justify-center mb-2">{icon}</div>
      <p className={`font-medium ${active ? 'text-primary-700' : 'text-gray-700'}`}>
        {title}
      </p>
    </button>
  )
}

function CreateForm({ onSubmit, loading }) {
  const [formData, setFormData] = useState({
    plotId: '',
    ownerId: '',
    ownerName: '',
    area: '',
    location: ''
  })

  const handleSubmit = async (e) => {
    e.preventDefault()
    const data = {
      ...formData,
      area: parseFloat(formData.area)
    }
    const success = await onSubmit(data)
    if (success) {
      setFormData({ plotId: '', ownerId: '', ownerName: '', area: '', location: '' })
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <h2 className="text-xl font-semibold text-gray-900 mb-6">Create Land Record</h2>
      <div className="grid md:grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Plot ID</label>
          <input
            type="text"
            value={formData.plotId}
            onChange={(e) => setFormData({ ...formData, plotId: e.target.value.toUpperCase() })}
            className="input-field"
            required
            disabled={loading}
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Owner ID</label>
          <input
            type="text"
            value={formData.ownerId}
            onChange={(e) => setFormData({ ...formData, ownerId: e.target.value.toUpperCase() })}
            className="input-field"
            required
            disabled={loading}
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Owner Name</label>
          <input
            type="text"
            value={formData.ownerName}
            onChange={(e) => setFormData({ ...formData, ownerName: e.target.value })}
            className="input-field"
            required
            disabled={loading}
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Area</label>
          <input
            type="number"
            step="0.01"
            min="0.01"
            value={formData.area}
            onChange={(e) => setFormData({ ...formData, area: e.target.value })}
            className="input-field"
            required
            disabled={loading}
          />
        </div>
        <div className="md:col-span-2">
          <label className="block text-sm font-medium text-gray-700 mb-2">Location</label>
          <input
            type="text"
            value={formData.location}
            onChange={(e) => setFormData({ ...formData, location: e.target.value })}
            className="input-field"
            required
            disabled={loading}
          />
        </div>
      </div>
      <button type="submit" className="btn-primary w-full" disabled={loading}>
        {loading ? 'Creating...' : 'Create Record'}
      </button>
    </form>
  )
}

function TransferForm({ onSubmit, loading }) {
  const [formData, setFormData] = useState({
    plotId: '',
    newOwnerId: '',
    newOwnerName: ''
  })

  const handleSubmit = async (e) => {
    e.preventDefault()
    const success = await onSubmit(formData)
    if (success) {
      setFormData({ plotId: '', newOwnerId: '', newOwnerName: '' })
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <h2 className="text-xl font-semibold text-gray-900 mb-6">Transfer Land Ownership</h2>
      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Plot ID</label>
          <input
            type="text"
            value={formData.plotId}
            onChange={(e) => setFormData({ ...formData, plotId: e.target.value.toUpperCase() })}
            className="input-field"
            required
            disabled={loading}
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">New Owner ID</label>
          <input
            type="text"
            value={formData.newOwnerId}
            onChange={(e) => setFormData({ ...formData, newOwnerId: e.target.value.toUpperCase() })}
            className="input-field"
            required
            disabled={loading}
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">New Owner Name</label>
          <input
            type="text"
            value={formData.newOwnerName}
            onChange={(e) => setFormData({ ...formData, newOwnerName: e.target.value })}
            className="input-field"
            required
            disabled={loading}
          />
        </div>
      </div>
      <button type="submit" className="btn-primary w-full" disabled={loading}>
        {loading ? 'Transferring...' : 'Transfer Ownership'}
      </button>
    </form>
  )
}

function StatusForm({ onSubmit, loading }) {
  const [formData, setFormData] = useState({
    plotId: '',
    status: 'active'
  })

  const handleSubmit = async (e) => {
    e.preventDefault()
    const success = await onSubmit(formData)
    if (success) {
      setFormData({ plotId: '', status: 'active' })
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <h2 className="text-xl font-semibold text-gray-900 mb-6">Update Land Status</h2>
      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Plot ID</label>
          <input
            type="text"
            value={formData.plotId}
            onChange={(e) => setFormData({ ...formData, plotId: e.target.value.toUpperCase() })}
            className="input-field"
            required
            disabled={loading}
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Status</label>
          <select
            value={formData.status}
            onChange={(e) => setFormData({ ...formData, status: e.target.value })}
            className="input-field"
            required
            disabled={loading}
          >
            <option value="active">Active</option>
            <option value="pending">Pending</option>
            <option value="disputed">Disputed</option>
          </select>
        </div>
      </div>
      <button type="submit" className="btn-primary w-full" disabled={loading}>
        {loading ? 'Updating...' : 'Update Status'}
      </button>
    </form>
  )
}

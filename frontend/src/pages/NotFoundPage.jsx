import { Link } from 'react-router-dom'
import { Home, AlertCircle } from 'lucide-react'

export default function NotFoundPage() {
  return (
    <div className="max-w-2xl mx-auto text-center py-20">
      <AlertCircle className="w-16 h-16 text-gray-400 mx-auto mb-4" />
      <h1 className="text-4xl font-bold text-gray-900 mb-2">404</h1>
      <p className="text-xl text-gray-600 mb-8">Page not found</p>
      <Link to="/" className="btn-primary">
        <Home className="w-5 h-5 inline-block mr-2" />
        Go Home
      </Link>
    </div>
  )
}

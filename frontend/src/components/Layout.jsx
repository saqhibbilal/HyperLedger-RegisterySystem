import { Link, useLocation } from 'react-router-dom'
import { Home, Search, Shield, FileText } from 'lucide-react'

export default function Layout({ children }) {
    const location = useLocation()

    const isActive = (path) => location.pathname === path

    return (
        <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
            {/* Navigation */}
            <nav className="bg-white shadow-sharp border-b border-gray-200 sticky top-0 z-50">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="flex justify-between items-center h-16">
                        {/* Logo */}
                        <Link to="/" className="flex items-center space-x-2 group">
                            <div className="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center group-hover:bg-primary-700 transition-colors">
                                <FileText className="w-5 h-5 text-white" />
                            </div>
                            <span className="text-xl font-bold text-gray-900">Land Registry</span>
                        </Link>

                        {/* Navigation Links */}
                        <div className="flex items-center space-x-1">
                            <NavLink to="/" icon={<Home className="w-4 h-4" />} active={isActive('/')}>
                                Home
                            </NavLink>
                            <NavLink to="/search" icon={<Search className="w-4 h-4" />} active={isActive('/search')}>
                                Search
                            </NavLink>
                            <NavLink to="/admin" icon={<Shield className="w-4 h-4" />} active={isActive('/admin')}>
                                Admin
                            </NavLink>
                        </div>
                    </div>
                </div>
            </nav>

            {/* Main Content */}
            <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                {children}
            </main>

            {/* Footer */}
            <footer className="bg-white border-t border-gray-200 mt-16">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                    <div className="text-center text-gray-600 text-sm">
                        <p>Land Registry System • Powered by Hyperledger Fabric</p>
                        <p className="mt-1 text-gray-500">Secure • Immutable • Transparent</p>
                    </div>
                </div>
            </footer>
        </div>
    )
}

function NavLink({ to, icon, active, children }) {
    return (
        <Link
            to={to}
            className={`
        flex items-center space-x-2 px-4 py-2 rounded-lg font-medium transition-all duration-200
        ${active
                    ? 'bg-primary-50 text-primary-700'
                    : 'text-gray-700 hover:bg-gray-50 hover:text-gray-900'
                }
      `}
        >
            {icon}
            <span>{children}</span>
        </Link>
    )
}

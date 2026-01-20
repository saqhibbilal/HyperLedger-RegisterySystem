import { Link } from 'react-router-dom'
import { Search, Shield, FileText, Lock, TrendingUp, Clock } from 'lucide-react'

export default function HomePage() {
    return (
        <div>
            {/* Hero Section */}
            <div className="text-center mb-16">
                <h1 className="text-5xl font-bold text-gray-900 mb-4 tracking-tight">
                    Land Registry System
                </h1>
                <p className="text-xl text-gray-600 max-w-2xl mx-auto mb-8">
                    Secure, immutable, and transparent land ownership records powered by blockchain technology
                </p>
                <div className="flex justify-center gap-4">
                    <Link to="/search" className="btn-primary text-lg px-8 py-3">
                        <Search className="w-5 h-5 inline-block mr-2" />
                        Search Records
                    </Link>
                    <Link to="/admin" className="btn-secondary text-lg px-8 py-3">
                        <Shield className="w-5 h-5 inline-block mr-2" />
                        Admin Portal
                    </Link>
                </div>
            </div>

            {/* Features Grid */}
            <div className="grid md:grid-cols-3 gap-6 mb-16">
                <FeatureCard
                    icon={<Lock className="w-6 h-6 text-primary-600" />}
                    title="Secure & Immutable"
                    description="All land records are stored on a blockchain, ensuring tamper-proof ownership history"
                />
                <FeatureCard
                    icon={<FileText className="w-6 h-6 text-primary-600" />}
                    title="Complete History"
                    description="View the complete ownership transfer history for any land parcel"
                />
                <FeatureCard
                    icon={<TrendingUp className="w-6 h-6 text-primary-600" />}
                    title="Real-time Updates"
                    description="All changes are recorded instantly and permanently on the blockchain"
                />
            </div>

            {/* How It Works */}
            <div className="card max-w-4xl mx-auto">
                <h2 className="text-2xl font-bold text-gray-900 mb-6">How It Works</h2>
                <div className="space-y-6">
                    <Step number={1} title="Search Land Records">
                        Use the search function to find land records by Plot ID. View current ownership and details instantly.
                    </Step>
                    <Step number={2} title="View Ownership History">
                        Access the complete transfer history to see all past ownership changes with timestamps.
                    </Step>
                    <Step number={3} title="Authorized Updates">
                        Only authorized government organizations can create or update land records, ensuring trust and security.
                    </Step>
                </div>
            </div>
        </div>
    )
}

function FeatureCard({ icon, title, description }) {
    return (
        <div className="card text-center">
            <div className="flex justify-center mb-4">{icon}</div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">{title}</h3>
            <p className="text-gray-600">{description}</p>
        </div>
    )
}

function Step({ number, title, children }) {
    return (
        <div className="flex gap-4">
            <div className="flex-shrink-0">
                <div className="w-10 h-10 bg-primary-100 text-primary-700 rounded-full flex items-center justify-center font-bold">
                    {number}
                </div>
            </div>
            <div>
                <h3 className="font-semibold text-gray-900 mb-1">{title}</h3>
                <p className="text-gray-600">{children}</p>
            </div>
        </div>
    )
}

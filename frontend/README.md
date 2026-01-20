# Land Registry Frontend

Modern, clean frontend for the Land Registry System built with React and Tailwind CSS.

## Features

- 🎨 **Modern Design** - Clean, sharp UI with Inter font
- 📱 **Responsive** - Works seamlessly on all devices
- ⚡ **Fast** - Built with Vite for optimal performance
- 🔍 **Search** - Easy land record search functionality
- 📋 **Detailed Views** - Complete land ownership information
- 🛡️ **Admin Panel** - Secure admin operations
- 📜 **History Tracking** - View complete ownership history

## Prerequisites

- Node.js v18 or higher
- npm v9 or higher
- Backend API running (Phase 5)

## Installation

1. Install dependencies:
```bash
npm install
```

2. Configure API URL (optional):
Create `.env` file:
```env
VITE_API_URL=http://localhost:3000/api
```

## Usage

### Development

Start development server:
```bash
npm run dev
```

The app will be available at `http://localhost:3001`

### Production

Build for production:
```bash
npm run build
```

Preview production build:
```bash
npm run preview
```

## Project Structure

```
frontend/
├── src/
│   ├── components/     # Reusable UI components
│   │   └── Layout.jsx
│   ├── pages/          # Page components
│   │   ├── HomePage.jsx
│   │   ├── SearchPage.jsx
│   │   ├── RecordPage.jsx
│   │   ├── AdminPage.jsx
│   │   └── NotFoundPage.jsx
│   ├── services/       # API integration
│   │   └── api.js
│   ├── App.jsx         # Main app component
│   ├── main.jsx        # Entry point
│   └── index.css       # Global styles
├── index.html
├── vite.config.js
├── tailwind.config.js
└── package.json
```

## Pages

### Home Page
Landing page with features and quick access to search and admin.

### Search Page
Search for land records by Plot ID.

### Record Page
View detailed land record information:
- Ownership details
- Land information
- Complete transfer history

### Admin Page
Authorized operations:
- Create new land records
- Transfer ownership
- Update land status

## Design System

### Colors
- Primary: Blue (primary-600)
- Status: Green (active), Yellow (pending), Red (disputed)
- Background: Gray-50 to Gray-100 gradient

### Typography
- Font: Inter (Google Fonts)
- Weights: 300, 400, 500, 600, 700

### Components
- Cards with soft shadows
- Sharp borders for navigation
- Smooth transitions
- Focus states for accessibility

## API Integration

The frontend communicates with the backend API:
- Base URL: `http://localhost:3000/api`
- Uses axios for HTTP requests
- Automatic user ID header injection
- Error handling and loading states

## Responsive Design

Fully responsive design that works on:
- Mobile phones
- Tablets
- Desktops
- Large screens

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## Development

### Adding New Pages

1. Create page component in `src/pages/`
2. Add route in `src/App.jsx`
3. Add navigation link in `src/components/Layout.jsx`

### Styling

Uses Tailwind CSS utility classes. Custom styles in:
- `src/index.css` - Global styles and components
- `tailwind.config.js` - Theme configuration

### API Calls

All API calls are in `src/services/api.js`. Add new endpoints there.

## License

MIT

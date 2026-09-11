import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import { LocaleProvider } from './i18n.jsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <LocaleProvider>
    <App />
  </LocaleProvider>
)

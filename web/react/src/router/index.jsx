import { Routes, Route } from 'react-router-dom'
import Home from '../views/Home'
import CameraPreview from '../views/CameraPreview'

function Router() {
  return (
    <Routes>
      <Route path="/" element={<Home />} />
      <Route 
        path="/camera" 
        element={<CameraPreview />}
      />
    </Routes>
  )
}

export default Router


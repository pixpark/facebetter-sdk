import React from 'react'
import { BrowserRouter, Routes, Route } from 'react-router-dom'
import Home from './views/Home'
import BeautyPreview from './views/BeautyPreview'

/**
 * Main App component
 * Sets up React Router with two routes:
 * - "/" - Home page with feature grid
 * - "/camera" - Beauty preview page with camera/image processing
 */
function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/camera" element={<BeautyPreview />} />
      </Routes>
    </BrowserRouter>
  )
}

export default App

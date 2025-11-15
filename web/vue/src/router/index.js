import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'
import CameraPreview from '../views/CameraPreview.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'Home',
      component: Home
    },
    {
      path: '/camera',
      name: 'CameraPreview',
      component: CameraPreview,
      props: route => ({ initialTab: route.query.tab || null })
    }
  ]
})

export default router


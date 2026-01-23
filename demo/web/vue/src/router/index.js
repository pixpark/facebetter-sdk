import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'
import BeautyPreview from '../views/BeautyPreview.vue'

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
      name: 'BeautyPreview',
      component: BeautyPreview,
      props: route => ({ initialTab: route.query.tab || null })
    }
  ]
})

export default router


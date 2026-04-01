import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'LexSimHome',
      component: () => import('../views/LexSimHomeView.vue')
    },
    {
      path: '/lexsim/create',
      name: 'LexSimCreate',
      component: () => import('../views/LexSimCaseCreateView.vue')
    },
    {
      path: '/lexsim/prepare/:projectId',
      name: 'LexSimPrepare',
      component: () => import('../views/LexSimPrepareView.vue'),
      props: true
    },
    {
      path: '/court/:simulationId',
      name: 'CourtRoom',
      component: () => import('../views/CourtRoomView.vue'),
      props: true
    },
    {
      path: '/verdict-generate',
      name: 'VerdictGenerate',
      component: () => import('../views/VerdictGenerateView.vue')
    }
  ]
})

export default router

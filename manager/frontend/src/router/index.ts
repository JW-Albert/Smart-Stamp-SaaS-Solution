import { createRouter, createWebHistory } from 'vue-router'
import StampList from '../views/StampList.vue'
import ClientList from '../views/ClientList.vue'
import CalibrationPad from '../views/CalibrationPad.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      redirect: '/stamps'
    },
    {
      path: '/stamps',
      name: 'stamps',
      component: StampList
    },
    {
      path: '/clients',
      name: 'clients',
      component: ClientList
    },
    {
      path: '/calibration',
      name: 'calibration',
      component: CalibrationPad
    }
  ]
})

export default router


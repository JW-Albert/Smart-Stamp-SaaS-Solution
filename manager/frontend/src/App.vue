<template>
  <a-layout style="min-height: 100vh">
    <a-layout-header style="background: #001529; padding: 0 24px">
      <div style="color: white; font-size: 20px; font-weight: bold">
        Smart Stamp 管理後台
      </div>
    </a-layout-header>
    <a-layout>
      <a-layout-sider width="200" style="background: #fff">
        <a-menu
          v-model:selectedKeys="selectedKeys"
          mode="inline"
          :style="{ height: '100%', borderRight: 0 }"
        >
          <a-menu-item key="stamps">
            <router-link to="/stamps">印章管理</router-link>
          </a-menu-item>
          <a-menu-item key="clients">
            <router-link to="/clients">客戶管理</router-link>
          </a-menu-item>
          <a-menu-item key="calibration">
            <router-link to="/calibration">印章校正</router-link>
          </a-menu-item>
        </a-menu>
      </a-layout-sider>
      <a-layout-content style="padding: 24px; background: #fff">
        <router-view />
      </a-layout-content>
    </a-layout>
  </a-layout>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()
const selectedKeys = ref([route.name as string])
</script>


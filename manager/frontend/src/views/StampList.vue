<template>
  <div>
    <a-page-header title="印章管理" />
    <a-table
      :columns="columns"
      :data-source="stamps"
      :loading="loading"
      :pagination="{ pageSize: 10 }"
      row-key="id"
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'action'">
          <a-button type="link" danger @click="handleDelete(record.id)">刪除</a-button>
        </template>
      </template>
    </a-table>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { stampApi } from '../api/client'

const stamps = ref([])
const loading = ref(false)

const columns = [
  { title: 'ID', dataIndex: 'id', key: 'id' },
  { title: '名稱', dataIndex: 'name', key: 'name' },
  { title: '描述', dataIndex: 'description', key: 'description' },
  { title: '建立時間', dataIndex: 'created_at', key: 'created_at' },
  { title: '操作', key: 'action' }
]

const fetchStamps = async () => {
  loading.value = true
  try {
    const res = await stampApi.list()
    stamps.value = res.data
  } catch (error) {
    message.error('載入印章列表失敗')
  } finally {
    loading.value = false
  }
}

const handleDelete = async (id: number) => {
  try {
    await stampApi.delete(id)
    message.success('刪除成功')
    fetchStamps()
  } catch (error) {
    message.error('刪除失敗')
  }
}

onMounted(() => {
  fetchStamps()
})
</script>


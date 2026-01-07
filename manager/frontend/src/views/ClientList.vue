<template>
  <div>
    <a-page-header title="客戶管理">
      <template #extra>
        <a-button type="primary" @click="showModal = true">新增客戶</a-button>
      </template>
    </a-page-header>
    <a-table
      :columns="columns"
      :data-source="clients"
      :loading="loading"
      :pagination="{ pageSize: 10 }"
      row-key="id"
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'status'">
          <a-tag :color="record.is_active ? 'green' : 'red'">
            {{ record.is_active ? '啟用' : '停用' }}
          </a-tag>
        </template>
        <template v-if="column.key === 'api_key'">
          <a-typography-text copyable>{{ record.api_key }}</a-typography-text>
        </template>
        <template v-if="column.key === 'action'">
          <a-button
            type="link"
            @click="handleManagePermissions(record)"
          >
            管理權限
          </a-button>
          <a-button
            type="link"
            @click="handleToggleStatus(record.id)"
          >
            {{ record.is_active ? '停用' : '啟用' }}
          </a-button>
        </template>
      </template>
    </a-table>

    <a-modal
      v-model:open="showModal"
      title="新增客戶"
      @ok="handleCreate"
    >
      <a-form :model="form">
        <a-form-item label="客戶名稱">
          <a-input v-model:value="form.name" />
        </a-form-item>
      </a-form>
    </a-modal>

    <!-- 權限管理模態框 -->
    <a-modal
      v-model:open="permissionModalVisible"
      title="管理客戶權限"
      width="800px"
      @ok="handleSavePermissions"
    >
      <div v-if="selectedClient">
        <a-typography-title :level="5">客戶：{{ selectedClient.name }}</a-typography-title>
        <a-divider />
        
        <a-typography-title :level="5">已綁定的印章</a-typography-title>
        <a-table
          :columns="permissionColumns"
          :data-source="clientPermissions"
          :loading="permissionLoading"
          :pagination="false"
          size="small"
          style="margin-bottom: 20px"
        >
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'action'">
              <a-button
                type="link"
                danger
                size="small"
                @click="handleRemovePermission(record.id)"
              >
                移除
              </a-button>
            </template>
          </template>
        </a-table>

        <a-divider />

        <a-typography-title :level="5">添加印章權限</a-typography-title>
        <a-select
          v-model:value="selectedStampId"
          placeholder="選擇要綁定的印章"
          style="width: 100%"
          show-search
          :filter-option="filterStampOption"
        >
          <a-select-option
            v-for="stamp in unboundStamps"
            :key="stamp.id"
            :value="stamp.id"
          >
            {{ stamp.name }} (ID: {{ stamp.id }})
          </a-select-option>
        </a-select>
        <div v-if="unboundStamps.length === 0" style="margin-top: 10px; color: #999">
          所有印章都已綁定
        </div>
      </div>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { clientApi, permissionApi, stampApi } from '../api/client'

const clients = ref([])
const loading = ref(false)
const showModal = ref(false)
const form = ref({ name: '' })

// 權限管理相關
const permissionModalVisible = ref(false)
const selectedClient = ref<any>(null)
const clientPermissions = ref([])
const permissionLoading = ref(false)
const availableStamps = ref([])
const selectedStampId = ref<number | null>(null)

const permissionColumns = [
  { title: '印章 ID', dataIndex: 'stamp_id', key: 'stamp_id' },
  { title: '印章名稱', dataIndex: 'stamp_name', key: 'stamp_name' },
  { title: '綁定時間', dataIndex: 'created_at', key: 'created_at' },
  { title: '操作', key: 'action' }
]

// 計算未綁定的印章
const unboundStamps = computed(() => {
  const boundStampIds = new Set(clientPermissions.value.map((p: any) => p.stamp_id))
  return availableStamps.value.filter((s: any) => !boundStampIds.has(s.id))
})

const columns = [
  { title: 'ID', dataIndex: 'id', key: 'id' },
  { title: '名稱', dataIndex: 'name', key: 'name' },
  { title: 'API Key', dataIndex: 'api_key', key: 'api_key' },
  { title: '狀態', key: 'status' },
  { title: '建立時間', dataIndex: 'created_at', key: 'created_at' },
  { title: '操作', key: 'action' }
]

const fetchClients = async () => {
  loading.value = true
  try {
    const res = await clientApi.list()
    clients.value = res.data
  } catch (error) {
    message.error('載入客戶列表失敗')
  } finally {
    loading.value = false
  }
}

const handleCreate = async () => {
  try {
    await clientApi.create({ name: form.value.name })
    message.success('建立成功')
    showModal.value = false
    form.value.name = ''
    fetchClients()
  } catch (error) {
    message.error('建立失敗')
  }
}

const handleToggleStatus = async (id: number) => {
  try {
    await clientApi.toggleStatus(id)
    message.success('狀態更新成功')
    fetchClients()
  } catch (error) {
    message.error('狀態更新失敗')
  }
}

const handleManagePermissions = async (client: any) => {
  selectedClient.value = client
  permissionModalVisible.value = true
  selectedStampId.value = null
  
  // 載入印章列表
  try {
    const stampsRes = await stampApi.list()
    availableStamps.value = stampsRes.data
  } catch (error) {
    message.error('載入印章列表失敗')
  }
  
  // 載入客戶的權限
  await fetchClientPermissions(client.id)
}

const fetchClientPermissions = async (clientId: number) => {
  permissionLoading.value = true
  try {
    const res = await permissionApi.list({ client_id: clientId })
    const permissions = res.data.filter((p: any) => p.is_active)
    
    // 獲取印章名稱
    const stampsRes = await stampApi.list()
    const stampsMap = new Map(stampsRes.data.map((s: any) => [s.id, s]))
    
    clientPermissions.value = permissions.map((p: any) => ({
      ...p,
      stamp_name: stampsMap.get(p.stamp_id)?.name || '未知'
    }))
  } catch (error) {
    message.error('載入權限列表失敗')
  } finally {
    permissionLoading.value = false
  }
}

const handleSavePermissions = async () => {
  if (!selectedStampId.value || !selectedClient.value) {
    message.warning('請選擇要綁定的印章')
    return
  }
  
  try {
    await permissionApi.create({
      client_id: selectedClient.value.id,
      stamp_id: selectedStampId.value
    })
    message.success('權限綁定成功')
    selectedStampId.value = null
    await fetchClientPermissions(selectedClient.value.id)
  } catch (error: any) {
    const errorMsg = error.response?.data?.detail || '綁定失敗'
    message.error(errorMsg)
  }
}

const handleRemovePermission = async (permissionId: number) => {
  try {
    await permissionApi.delete(permissionId)
    message.success('權限已移除')
    if (selectedClient.value) {
      await fetchClientPermissions(selectedClient.value.id)
    }
  } catch (error) {
    message.error('移除權限失敗')
  }
}

const filterStampOption = (input: string, option: any) => {
  const text = option.children?.[0]?.children || option.label || ''
  return text.toLowerCase().includes(input.toLowerCase())
}

onMounted(() => {
  fetchClients()
})
</script>


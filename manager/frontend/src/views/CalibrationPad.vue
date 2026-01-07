<template>
  <div>
    <a-page-header title="印章校正" />
    <div style="margin-bottom: 16px">
      <a-form :model="form" layout="inline">
        <a-form-item label="印章名稱">
          <a-input v-model:value="form.name" style="width: 200px" />
        </a-form-item>
        <a-form-item label="描述">
          <a-input v-model:value="form.description" style="width: 200px" />
        </a-form-item>
        <a-form-item>
          <a-button type="primary" :disabled="points.length !== 5" @click="handleRegister">
            註冊印章
          </a-button>
          <a-button style="margin-left: 8px" @click="handleClear">清除</a-button>
        </a-form-item>
      </a-form>
    </div>
    <div style="position: relative">
      <canvas
        ref="canvasRef"
        style="border: 2px solid #d9d9d9; cursor: crosshair; display: block; width: 100%; height: 70vh"
        @touchstart="handleTouchStart"
        @touchend="handleTouchEnd"
        @mousedown="handleMouseDown"
      />
      <div
        v-if="points.length > 0"
        style="position: absolute; top: 10px; right: 10px; background: rgba(0,0,0,0.7); color: white; padding: 8px; border-radius: 4px"
      >
        已記錄 {{ points.length }} / 5 個觸控點
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, nextTick } from 'vue'
import { message } from 'ant-design-vue'
import { stampApi } from '../api/client'

const canvasRef = ref<HTMLCanvasElement | null>(null)
const points = ref<Array<{ x: number; y: number }>>([])
const form = ref({
  name: '',
  description: ''
})

let ctx: CanvasRenderingContext2D | null = null
let devicePixelRatio = 1

onMounted(() => {
  if (canvasRef.value) {
    const canvas = canvasRef.value
    ctx = canvas.getContext('2d')
    devicePixelRatio = window.devicePixelRatio || 1
    
    // 設定 canvas 尺寸（考慮設備像素比，確保高解析度顯示）
    const resizeCanvas = () => {
      const rect = canvas.getBoundingClientRect()
      const dpr = window.devicePixelRatio || 1
      
      // 設定實際像素尺寸（考慮設備像素比）
      canvas.width = rect.width * dpr
      canvas.height = rect.height * dpr
      
      // 設定顯示尺寸（CSS 尺寸）
      canvas.style.width = rect.width + 'px'
      canvas.style.height = rect.height + 'px'
      
      // 縮放繪圖上下文以匹配設備像素比
      if (ctx) {
        ctx.scale(dpr, dpr)
      }
      
      redraw()
    }
    
    resizeCanvas()
    window.addEventListener('resize', resizeCanvas)
    window.addEventListener('orientationchange', () => {
      setTimeout(resizeCanvas, 100)
    })
  }
})

const redraw = () => {
  if (!canvasRef.value || !ctx) return
  
  const canvas = canvasRef.value
  const rect = canvas.getBoundingClientRect()
  
  // 清除畫布（使用顯示尺寸）
  ctx.clearRect(0, 0, rect.width, rect.height)
  
  // 繪製已記錄的觸控點（使用顯示座標）
  points.value.forEach((point, index) => {
    ctx!.fillStyle = '#1890ff'
    ctx!.beginPath()
    ctx!.arc(point.x, point.y, 15, 0, Math.PI * 2)
    ctx!.fill()
    
    // 標示編號
    ctx!.fillStyle = 'white'
    ctx!.font = '14px Arial'
    ctx!.textAlign = 'center'
    ctx!.textBaseline = 'middle'
    ctx!.fillText(String(index + 1), point.x, point.y)
  })
}

const getCanvasCoordinates = (clientX: number, clientY: number) => {
  const canvas = canvasRef.value
  if (!canvas) return { x: 0, y: 0 }
  
  const rect = canvas.getBoundingClientRect()
  // 計算相對於 Canvas 的座標（使用實際顯示尺寸，不考慮設備像素比）
  // 因為我們已經在 resizeCanvas 中處理了設備像素比的縮放
  const x = clientX - rect.left
  const y = clientY - rect.top
  
  return { x, y }
}

const handleTouchStart = (e: TouchEvent) => {
  e.preventDefault()
  
  if (points.value.length >= 5) {
    message.warning('最多只能記錄 5 個觸控點')
    return
  }
  
  if (e.touches.length === 5) {
    // 同時偵測到 5 點觸控
    const newPoints = Array.from(e.touches).map(touch => 
      getCanvasCoordinates(touch.clientX, touch.clientY)
    )
    
    points.value = newPoints
    redraw()
    message.success('已記錄 5 個觸控點')
  } else if (e.touches.length === 1) {
    // 單點觸控（用於測試）
    const touch = e.touches[0]
    const point = getCanvasCoordinates(touch.clientX, touch.clientY)
    
    if (points.value.length < 5) {
      points.value.push(point)
      redraw()
      
      if (points.value.length === 5) {
        message.success('已記錄 5 個觸控點')
      }
    }
  }
}

const handleTouchEnd = (e: TouchEvent) => {
  e.preventDefault()
}

const handleMouseDown = (e: MouseEvent) => {
  // 滑鼠點擊（用於桌面測試）
  if (points.value.length >= 5) {
    message.warning('最多只能記錄 5 個觸控點')
    return
  }
  
  const point = getCanvasCoordinates(e.clientX, e.clientY)
  
  points.value.push(point)
  redraw()
  
  if (points.value.length === 5) {
    message.success('已記錄 5 個觸控點')
  }
}

const handleRegister = async () => {
  if (points.value.length !== 5) {
    message.error('必須記錄 5 個觸控點')
    return
  }
  
  if (!form.value.name) {
    message.error('請輸入印章名稱')
    return
  }
  
  try {
    const pointsArray = points.value.map(p => [p.x, p.y]) as [number, number][]
    await stampApi.calibrate({
      name: form.value.name,
      points: pointsArray,
      description: form.value.description || undefined
    })
    
    message.success('印章註冊成功')
    handleClear()
  } catch (error: any) {
    message.error(error.response?.data?.detail || '註冊失敗')
  }
}

const handleClear = () => {
  points.value = []
  form.value.name = ''
  form.value.description = ''
  redraw()
}
</script>


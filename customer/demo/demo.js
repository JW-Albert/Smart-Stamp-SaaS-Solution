/**
 * Smart Stamp Demo - 前端程式
 */
import { SmartStamp } from './SmartStamp.js'

// 配置
const CONFIG = {
  // 使用相對路徑，透過當前後端轉發
  API_URL: '/api/verify',
  API_KEY: 'sk_df76747fd14a407c863b7f0c69a3b6fb' // 您的 API Key
}

// 等待 DOM 載入完成
let stampArea, startBtn, stopBtn, clearBtn, statusEl, touchCountEl, jwtTokenEl, logContainer

function initDOM() {
  stampArea = document.getElementById('stamp-area')
  startBtn = document.getElementById('start-btn')
  stopBtn = document.getElementById('stop-btn')
  clearBtn = document.getElementById('clear-btn')
  statusEl = document.getElementById('status')
  touchCountEl = document.getElementById('touch-count')
  jwtTokenEl = document.getElementById('jwt-token')
  logContainer = document.getElementById('log-container')

  // 檢查 DOM 元素是否存在
  if (!stampArea || !startBtn || !stopBtn || !clearBtn || !statusEl || !touchCountEl || !jwtTokenEl || !logContainer) {
    console.error('無法找到必要的 DOM 元素', {
      stampArea: !!stampArea,
      startBtn: !!startBtn,
      stopBtn: !!stopBtn,
      clearBtn: !!clearBtn,
      statusEl: !!statusEl,
      touchCountEl: !!touchCountEl,
      jwtTokenEl: !!jwtTokenEl,
      logContainer: !!logContainer
    })
    return false
  }
  return true
}

// 狀態
let smartStamp = null
let touchPoints = []

// 初始化 SmartStamp
function initSmartStamp() {
  smartStamp = new SmartStamp({
    targetElement: stampArea,
    touchPoints: 5,
    onCoordinates: handleCoordinates,
    onError: handleError
  })

  // 監聽自定義事件
  stampArea.addEventListener('smartstamp:coordinates', (event) => {
    const { points, rawPoints } = event.detail
    displayTouchPoints(rawPoints)
  })
}

// 處理座標回調
async function handleCoordinates(points) {
  touchPoints = points
  touchCountEl.textContent = points.length
  addLog('收到座標資料', 'info')

  // 將座標傳送到後端
  try {
    const response = await fetch(CONFIG.API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ points })
    })

    const data = await response.json()

    if (response.ok) {
      addLog('驗證成功', 'success')
      if (data.jwt_token) {
        jwtTokenEl.textContent = data.jwt_token.substring(0, 50) + '...'
        addLog(`JWT Token: ${data.jwt_token.substring(0, 50)}...`, 'success')
        if (data.jwt_verified) {
          addLog('JWT 簽章驗證成功', 'success')
        }
      } else {
        jwtTokenEl.textContent = '-'
      }
    } else {
      addLog(`驗證失敗: ${data.detail || data.error || '未知錯誤'}`, 'error')
      jwtTokenEl.textContent = '-'
    }
  } catch (error) {
    addLog(`請求錯誤: ${error.message}`, 'error')
    jwtTokenEl.textContent = '-'
  }
}

// 處理錯誤
function handleError(error) {
  addLog(`錯誤: ${error.message}`, 'error')
}

// 顯示觸控點
function displayTouchPoints(points) {
  // 清除舊的觸控點
  document.querySelectorAll('.touch-point').forEach(el => el.remove())

  // 顯示新的觸控點
  points.forEach((point, index) => {
    const dot = document.createElement('div')
    dot.className = 'touch-point'
    dot.textContent = index + 1
    dot.style.left = `${point.x}px`
    dot.style.top = `${point.y}px`
    stampArea.appendChild(dot)
  })

  stampArea.classList.add('active')
  setTimeout(() => {
    stampArea.classList.remove('active')
  }, 1000)
}

// 添加日誌
function addLog(message, type = 'info') {
  const logItem = document.createElement('div')
  logItem.className = `log-item ${type}`
  logItem.textContent = `[${new Date().toLocaleTimeString()}] ${message}`
  logContainer.insertBefore(logItem, logContainer.firstChild)

  // 限制日誌數量
  while (logContainer.children.length > 50) {
    logContainer.removeChild(logContainer.lastChild)
  }
}

// 初始化事件監聽器
function initEventListeners() {
  if (!startBtn || !stopBtn || !clearBtn) {
    console.error('按鈕元素不存在，無法綁定事件')
    return
  }

  // 開始
  startBtn.addEventListener('click', () => {
    try {
      if (!smartStamp) {
        initSmartStamp()
      }
      if (smartStamp) {
        smartStamp.start()
        statusEl.textContent = '運行中'
        addLog('SmartStamp 已啟動', 'info')
      } else {
        addLog('錯誤: SmartStamp 初始化失敗', 'error')
      }
    } catch (error) {
      addLog(`錯誤: ${error.message}`, 'error')
      console.error('啟動錯誤:', error)
    }
  })

  // 停止
  stopBtn.addEventListener('click', () => {
    if (smartStamp) {
      smartStamp.stop()
      statusEl.textContent = '已停止'
      addLog('SmartStamp 已停止', 'info')
    }
  })

  // 清除
  clearBtn.addEventListener('click', () => {
    document.querySelectorAll('.touch-point').forEach(el => el.remove())
    touchPoints = []
    touchCountEl.textContent = '0'
    jwtTokenEl.textContent = '-'
    logContainer.innerHTML = ''
    addLog('已清除', 'info')
  })
}

// 初始化
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    if (initDOM()) {
      initEventListeners()
      addLog('Demo 已載入', 'info')
    }
  })
} else {
  // DOM 已經載入
  if (initDOM()) {
    initEventListeners()
    addLog('Demo 已載入', 'info')
  }
}

// 錯誤處理
window.addEventListener('error', (event) => {
  console.error('頁面錯誤:', event.error)
  if (logContainer) {
    addLog(`載入錯誤: ${event.error?.message || event.message}`, 'error')
  }
})

// 處理模組載入錯誤
window.addEventListener('unhandledrejection', (event) => {
  console.error('未處理的 Promise 拒絕:', event.reason)
  if (logContainer) {
    addLog(`模組載入錯誤: ${event.reason?.message || event.reason}`, 'error')
  }
})


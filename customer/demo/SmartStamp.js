/**
 * Smart Stamp SDK - JavaScript 版本
 * 負責採集觸控、座標正規化（初步處理）、轉發給客戶後端
 */

export class SmartStamp {
  constructor(config) {
    // 解析目標元素
    if (typeof config.targetElement === 'string') {
      const element = document.querySelector(config.targetElement)
      if (!element) {
        throw new Error(`找不到目標元素: ${config.targetElement}`)
      }
      this.targetElement = element
    } else {
      this.targetElement = config.targetElement
    }

    this.touchPoints = config.touchPoints || 5
    this.onCoordinates = config.onCoordinates
    this.onError = config.onError
    this.isActive = false
    this.currentTouches = []

    // 綁定事件處理器
    this.handleTouchStart = this.handleTouchStart.bind(this)
    this.handleTouchEnd = this.handleTouchEnd.bind(this)
    this.handleTouchCancel = this.handleTouchCancel.bind(this)
  }

  start() {
    if (this.isActive) {
      console.warn('SmartStamp 已經在運行中')
      return
    }

    this.isActive = true
    this.targetElement.addEventListener('touchstart', this.handleTouchStart, { passive: false })
    this.targetElement.addEventListener('touchend', this.handleTouchEnd, { passive: false })
    this.targetElement.addEventListener('touchcancel', this.handleTouchCancel, { passive: false })
    this.targetElement.addEventListener('mousedown', this.handleMouseDown.bind(this))

    // 觸發自定義事件
    this.targetElement.dispatchEvent(
      new CustomEvent('smartstamp:start', { detail: { timestamp: Date.now() } })
    )
  }

  stop() {
    if (!this.isActive) {
      return
    }

    this.isActive = false
    this.targetElement.removeEventListener('touchstart', this.handleTouchStart)
    this.targetElement.removeEventListener('touchend', this.handleTouchEnd)
    this.targetElement.removeEventListener('touchcancel', this.handleTouchCancel)
    this.targetElement.removeEventListener('mousedown', this.handleMouseDown)

    // 觸發自定義事件
    this.targetElement.dispatchEvent(
      new CustomEvent('smartstamp:stop', { detail: { timestamp: Date.now() } })
    )
  }

  handleTouchStart(event) {
    if (!this.isActive) {
      return
    }

    event.preventDefault()

    // 更新當前觸控點
    this.currentTouches = Array.from(event.touches)

    // 檢查是否達到所需的觸控點數量
    if (this.currentTouches.length === this.touchPoints) {
      this.processCoordinates()
    } else if (this.currentTouches.length > this.touchPoints) {
      // 超過所需數量，只取前 N 個
      this.currentTouches = this.currentTouches.slice(0, this.touchPoints)
      this.processCoordinates()
    }
  }

  handleTouchEnd(event) {
    if (!this.isActive) {
      return
    }

    // 清除當前觸控點
    this.currentTouches = []
  }

  handleTouchCancel(event) {
    if (!this.isActive) {
      return
    }

    // 清除當前觸控點
    this.currentTouches = []
  }

  handleMouseDown(event) {
    // 滑鼠點擊（用於桌面測試）
    if (!this.isActive) {
      return
    }

    if (this.currentTouches.length >= this.touchPoints) {
      return
    }

    const rect = this.targetElement.getBoundingClientRect()
    const touch = {
      clientX: event.clientX,
      clientY: event.clientY
    }

    this.currentTouches.push(touch)

    if (this.currentTouches.length === this.touchPoints) {
      this.processCoordinates()
    }
  }

  processCoordinates() {
    try {
      const rect = this.targetElement.getBoundingClientRect()
      const points = this.currentTouches.map(touch => ({
        x: touch.clientX - rect.left,
        y: touch.clientY - rect.top
      }))

      // 正規化座標（相對於元素尺寸）
      const normalizedPoints = this.normalizeCoordinates(points, rect)

      // 觸發回調
      if (this.onCoordinates) {
        this.onCoordinates(normalizedPoints)
      }

      // 觸發自定義事件
      this.targetElement.dispatchEvent(
        new CustomEvent('smartstamp:coordinates', {
          detail: {
            points: normalizedPoints,
            rawPoints: points,
            timestamp: Date.now()
          }
        })
      )
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error))
      if (this.onError) {
        this.onError(err)
      }
      this.targetElement.dispatchEvent(
        new CustomEvent('smartstamp:error', {
          detail: { error: err, timestamp: Date.now() }
        })
      )
    }
  }

  normalizeCoordinates(points, rect) {
    if (rect.width === 0 || rect.height === 0) {
      throw new Error('目標元素尺寸為 0')
    }

    return points.map(point => ({
      x: point.x / rect.width,
      y: point.y / rect.height
    }))
  }

  destroy() {
    this.stop()
    this.onCoordinates = undefined
    this.onError = undefined
  }
}


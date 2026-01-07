/**
 * Smart Stamp SDK
 * 負責採集觸控、座標正規化（初步處理）、轉發給客戶後端
 */

export interface SmartStampConfig {
  /** 目標元素（觸控區域） */
  targetElement: HTMLElement | string
  /** 觸控點數量（預設 5） */
  touchPoints?: number
  /** 座標回調函數 */
  onCoordinates?: (points: Point[]) => void
  /** 錯誤回調函數 */
  onError?: (error: Error) => void
}

export interface Point {
  x: number
  y: number
}

export class SmartStamp {
  private targetElement: HTMLElement
  private touchPoints: number
  private onCoordinates?: (points: Point[]) => void
  private onError?: (error: Error) => void
  private isActive: boolean = false
  private currentTouches: Touch[] = []

  constructor(config: SmartStampConfig) {
    // 解析目標元素
    if (typeof config.targetElement === 'string') {
      const element = document.querySelector(config.targetElement) as HTMLElement
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

    // 綁定事件處理器
    this.handleTouchStart = this.handleTouchStart.bind(this)
    this.handleTouchEnd = this.handleTouchEnd.bind(this)
    this.handleTouchCancel = this.handleTouchCancel.bind(this)
  }

  /**
   * 開始監聽觸控事件
   */
  start(): void {
    if (this.isActive) {
      console.warn('SmartStamp 已經在運行中')
      return
    }

    this.isActive = true
    this.targetElement.addEventListener('touchstart', this.handleTouchStart, { passive: false })
    this.targetElement.addEventListener('touchend', this.handleTouchEnd, { passive: false })
    this.targetElement.addEventListener('touchcancel', this.handleTouchCancel, { passive: false })

    // 觸發自定義事件
    this.targetElement.dispatchEvent(
      new CustomEvent('smartstamp:start', { detail: { timestamp: Date.now() } })
    )
  }

  /**
   * 停止監聽觸控事件
   */
  stop(): void {
    if (!this.isActive) {
      return
    }

    this.isActive = false
    this.targetElement.removeEventListener('touchstart', this.handleTouchStart)
    this.targetElement.removeEventListener('touchend', this.handleTouchEnd)
    this.targetElement.removeEventListener('touchcancel', this.handleTouchCancel)

    // 觸發自定義事件
    this.targetElement.dispatchEvent(
      new CustomEvent('smartstamp:stop', { detail: { timestamp: Date.now() } })
    )
  }

  /**
   * 處理觸控開始事件
   */
  private handleTouchStart(event: TouchEvent): void {
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

  /**
   * 處理觸控結束事件
   */
  private handleTouchEnd(event: TouchEvent): void {
    if (!this.isActive) {
      return
    }

    // 清除當前觸控點
    this.currentTouches = []
  }

  /**
   * 處理觸控取消事件
   */
  private handleTouchCancel(event: TouchEvent): void {
    if (!this.isActive) {
      return
    }

    // 清除當前觸控點
    this.currentTouches = []
  }

  /**
   * 處理座標：正規化並回傳
   */
  private processCoordinates(): void {
    try {
      const rect = this.targetElement.getBoundingClientRect()
      const points: Point[] = this.currentTouches.map(touch => ({
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

  /**
   * 正規化座標（相對於元素尺寸，轉換為 0.0~1.0 的比例）
   */
  private normalizeCoordinates(points: Point[], rect: DOMRect): Point[] {
    if (rect.width === 0 || rect.height === 0) {
      throw new Error('目標元素尺寸為 0')
    }

    return points.map(point => ({
      x: point.x / rect.width,
      y: point.y / rect.height
    }))
  }

  /**
   * 銷毀實例
   */
  destroy(): void {
    this.stop()
    this.onCoordinates = undefined
    this.onError = undefined
  }
}

// 導出預設實例工廠函數
export default function createSmartStamp(config: SmartStampConfig): SmartStamp {
  return new SmartStamp(config)
}


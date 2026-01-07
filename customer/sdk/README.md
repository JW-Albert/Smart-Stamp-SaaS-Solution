# Smart Stamp SDK

提供給客戶的 Web SDK，負責採集觸控、座標正規化（初步處理）、轉發給客戶後端。

## 技術棧

- TypeScript
- Vite (Library Mode)

## 安裝

```bash
npm install
```

## 建置

```bash
npm run build
```

輸出檔案位於 `dist/` 目錄：
- `smart-stamp.es.js` - ES Module 格式
- `smart-stamp.umd.js` - UMD 格式

## 使用方式

### ES Module

```javascript
import { SmartStamp } from 'smart-stamp-sdk'

const stamp = new SmartStamp({
  targetElement: '#stamp-area',
  touchPoints: 5,
  onCoordinates: (points) => {
    console.log('收到座標:', points)
    // 將座標傳送到後端
    fetch('/api/verify', {
      method: 'POST',
      body: JSON.stringify({ points })
    })
  }
})

stamp.start()
```

### UMD (瀏覽器)

```html
<script src="./dist/smart-stamp.umd.js"></script>
<script>
  const stamp = new SmartStamp.SmartStamp({
    targetElement: '#stamp-area',
    touchPoints: 5,
    onCoordinates: (points) => {
      console.log('收到座標:', points)
    }
  })
  stamp.start()
</script>
```

### 自定義事件

SDK 也會觸發自定義事件，可以使用事件監聽器：

```javascript
const element = document.querySelector('#stamp-area')

element.addEventListener('smartstamp:coordinates', (event) => {
  const { points, rawPoints, timestamp } = event.detail
  console.log('座標:', points)
})
```

## API

### SmartStamp 類別

#### 建構函數

```typescript
new SmartStamp(config: SmartStampConfig)
```

#### 方法

- `start()`: 開始監聽觸控事件
- `stop()`: 停止監聽觸控事件
- `destroy()`: 銷毀實例

### 配置選項

```typescript
interface SmartStampConfig {
  targetElement: HTMLElement | string  // 目標元素
  touchPoints?: number                 // 觸控點數量（預設 5）
  onCoordinates?: (points: Point[]) => void  // 座標回調
  onError?: (error: Error) => void     // 錯誤回調
}
```


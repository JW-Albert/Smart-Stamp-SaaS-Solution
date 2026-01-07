# Smart Stamp 管理後台 - 前端

Vue 3 + Vite + Ant Design Vue 前端應用程式。

## 技術棧

- Vue 3
- Vite
- TypeScript
- Ant Design Vue

## 安裝與執行

### 1. 安裝依賴

```bash
npm install
```

### 2. 執行開發伺服器

```bash
npm run dev
```

應用程式將在 http://localhost:3000 啟動。

### 3. 建置生產版本

```bash
npm run build
```

## 功能

- **印章管理**：查看、刪除已註冊的印章
- **客戶管理**：建立客戶、生成 API Key、管理客戶狀態
- **印章校正**：使用 Canvas 記錄 5 點觸控，註冊新印章

## 頁面說明

### 印章校正頁面

- 全螢幕 Canvas 用於記錄觸控點
- 支援 5 指同時觸控（真實場景）
- 支援單點觸控（測試用）
- 支援滑鼠點擊（桌面測試）
- 記錄 5 個點後可註冊印章


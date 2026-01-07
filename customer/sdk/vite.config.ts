import { defineConfig } from 'vite'
import { resolve } from 'path'

export default defineConfig({
  build: {
    lib: {
      entry: resolve(__dirname, 'src/index.ts'),
      name: 'SmartStamp',
      fileName: (format) => `smart-stamp.${format}.js`,
      formats: ['es', 'umd']
    },
    rollupOptions: {
      output: {
        // 確保 UMD 格式的全局變數名稱
        globals: {
          'smart-stamp': 'SmartStamp'
        }
      }
    }
  }
})


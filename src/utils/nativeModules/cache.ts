import { NativeModules } from 'react-native'

const { CacheModule } = NativeModules

// iOS 上 CacheModule 不存在，提供空实现兜底
const SafeCacheModule = CacheModule ?? {
  getAppCacheSize: async () => 0,
  clearAppCache: async () => {},
}

export const getAppCacheSize = async (): Promise<number> =>
  SafeCacheModule.getAppCacheSize().then((size: number) => Math.trunc(size))

export const clearAppCache = SafeCacheModule.clearAppCache as () => Promise<void>

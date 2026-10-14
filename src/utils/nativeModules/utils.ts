import { AppState, BackHandler, Dimensions, NativeEventEmitter, NativeModules, Platform } from 'react-native'

const { UtilsModule } = NativeModules

// iOS 上 UtilsModule 不存在，提供空实现兜底，防止启动即崩
const SafeUtilsModule = UtilsModule ?? {
  exitApp: () => {
    if (Platform.OS === 'ios') {
      // iOS 不允许 App 主动退出，退到后台即可
      BackHandler.exitApp()
    }
  },
  getSupportedAbis: () => '',
  installApk: () => {},
  screenkeepAwake: () => {},
  screenUnkeepAwake: () => {},
  getWIFIIPV4Address: async () => '',
  getDeviceName: async () => 'Unknown',
  isNotificationsEnabled: async () => false,
  openNotificationPermissionActivity: async () => false,
  shareText: () => {},
  getSystemLocales: async () => '',
  listenWindowSizeChanged: () => {},
  isIgnoringBatteryOptimization: async () => false,
  requestIgnoreBatteryOptimization: async () => false,
}

export const exitApp = SafeUtilsModule.exitApp
export const getSupportedAbis = SafeUtilsModule.getSupportedAbis
export const installApk = (filePath: string, fileProviderAuthority: string) => SafeUtilsModule.installApk(filePath, fileProviderAuthority)

export const screenkeepAwake = () => {
  if (global.lx.isScreenKeepAwake) return
  global.lx.isScreenKeepAwake = true
  SafeUtilsModule.screenkeepAwake()
}

export const screenUnkeepAwake = () => {
  if (!global.lx.isScreenKeepAwake) return
  global.lx.isScreenKeepAwake = false
  SafeUtilsModule.screenUnkeepAwake()
}

export const getWIFIIPV4Address = SafeUtilsModule.getWIFIIPV4Address as () => Promise<string>

export const getDeviceName = async (): Promise<string> => {
  return SafeUtilsModule.getDeviceName().then((deviceName: string) => deviceName || 'Unknown')
}

export const isNotificationsEnabled = SafeUtilsModule.isNotificationsEnabled as () => Promise<boolean>

export const requestNotificationPermission = async () => new Promise<boolean>((resolve) => {
  let subscription = AppState.addEventListener('change', (state) => {
    if (state !== 'active') return
    subscription.remove()
    setTimeout(() => {
      void isNotificationsEnabled().then(resolve)
    }, 1000)
  })
  SafeUtilsModule.openNotificationPermissionActivity().then((result: boolean) => {
    if (result) return
    subscription.remove()
    resolve(false)
  })
})

export const shareText = async (shareTitle: string, title: string, text: string): Promise<void> => {
  SafeUtilsModule.shareText(shareTitle, title, text)
}

export const getSystemLocales = async (): Promise<string> => {
  return SafeUtilsModule.getSystemLocales()
}

export const onScreenStateChange = (_handler: (state: 'ON' | 'OFF') => void): (() => void) => {
  // iOS 无此事件，返回空取消函数
  return () => {}
}

export const getWindowSize = async (): Promise<{ width: number, height: number }> => {
  const win = Dimensions.get('window')
  return { width: win.width, height: win.height }
}

export const onWindowSizeChange = (_handler: (size: { width: number, height: number }) => void): (() => void) => {
  return () => {}
}

export const isIgnoringBatteryOptimization = async (): Promise<boolean> => {
  return SafeUtilsModule.isIgnoringBatteryOptimization()
}

export const requestIgnoreBatteryOptimization = async (): Promise<boolean> => {
  return SafeUtilsModule.requestIgnoreBatteryOptimization()
}

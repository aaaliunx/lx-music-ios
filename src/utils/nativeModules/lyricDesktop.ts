import { NativeModules } from 'react-native'

const { LyricModule } = NativeModules

// iOS 上 LyricModule 不存在，提供空实现兜底
const SafeLyricModule = LyricModule ?? new Proxy({}, {
  get: () => () => Promise.resolve(),
})

const getAlpha = (num: number) => num / 100
const getTextSize = (num: number) => num / 10

export const setSendLyricTextEvent = async (isSend: boolean) => {
  return SafeLyricModule.setSendLyricTextEvent(isSend)
}

export const showDesktopLyricView = async (): Promise<void> => {
  return SafeLyricModule.showDesktopLyric({})
}

export const hideDesktopLyricView = async (): Promise<void> => {
  return SafeLyricModule.hideDesktopLyric()
}

export const play = async (): Promise<void> => {
  return SafeLyricModule.play()
}

export const pause = async (): Promise<void> => {
  return SafeLyricModule.pause()
}

export const setLyric = async (): Promise<void> => {
  return SafeLyricModule.setLyric()
}

export const setPlaybackRate = async (): Promise<void> => {
  return SafeLyricModule.setPlaybackRate()
}

export const toggleTranslation = async (): Promise<void> => {
  return SafeLyricModule.toggleTranslation()
}

export const toggleRoma = async (): Promise<void> => {
  return SafeLyricModule.toggleRoma()
}

export const toggleLock = async (): Promise<void> => {
  return SafeLyricModule.toggleLock()
}

export const setColor = async (): Promise<void> => {
  return SafeLyricModule.setColor()
}

export const setAlpha = async (): Promise<void> => {
  return SafeLyricModule.setAlpha()
}

export const setTextSize = async (): Promise<void> => {
  return SafeLyricModule.setTextSize()
}

export const setShowToggleAnima = async (): Promise<void> => {
  return SafeLyricModule.setShowToggleAnima()
}

export const setSingleLine = async (): Promise<void> => {
  return SafeLyricModule.setSingleLine()
}

export const setPosition = async (): Promise<void> => {
  return SafeLyricModule.setPosition()
}

export const setMaxLineNum = async (): Promise<void> => {
  return SafeLyricModule.setMaxLineNum()
}

export const setWidth = async (): Promise<void> => {
  return SafeLyricModule.setWidth()
}

export const setLyricTextPosition = async (): Promise<void> => {
  return SafeLyricModule.setLyricTextPosition()
}

export const checkOverlayPermission = async (): Promise<void> => {
  return SafeLyricModule.checkOverlayPermission()
}

export const openOverlayPermissionActivity = async (): Promise<void> => {
  return SafeLyricModule.openOverlayPermissionActivity()
}

export const onPositionChange = (): (() => void) => {
  // iOS 上 LyricModule 不存在，返回空取消函数
  return () => {}
}

export const onLyricLinePlay = (): (() => void) => {
  // iOS 上 LyricModule 不存在，返回空取消函数
  return () => {}
}

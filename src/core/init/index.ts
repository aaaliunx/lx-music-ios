import { initSetting, showPactModal, updateSetting } from '@/core/common'
import registerPlaybackService from '@/plugins/player/service'
import initTheme from './theme'
import initI18n from './i18n'
import initUserApi from './userApi'
import initPlayer from './player'
import dataInit from './dataInit'
import initSync from './sync'
import initCommonState from './common'
import { initDeeplink } from './deeplink'
import { setApiSource } from '@/core/apiSource'
import commonActions from '@/store/common/action'
import settingState from '@/store/setting/state'
import { bootLog } from '@/utils/bootLog'
import { cheatTip } from '@/utils/tools'
import { Platform } from 'react-native'
import { getStatusBarHeight, getSafeAreaInsets } from '@/utils/nativeModules/utils'

let isFirstPush = true
const handlePushedHomeScreen = async () => {
  await cheatTip()
  // iOS 上自动同意协议，跳过弹窗
  if (!settingState.setting['common.isAgreePact']) {
    void updateSetting({ 'common.isAgreePact': true })
  }
  if (isFirstPush) {
    isFirstPush = false
    // void checkUpdate()  // 关闭自动更新检查
    void initDeeplink()
  }
}

let isInited = false
export default async () => {
  if (isInited) return handlePushedHomeScreen
  bootLog('Initing...')

  // iOS: 设置状态栏高度和安全区域
  if (Platform.OS === 'ios') {
    try {
      const statusBarHeight = await getStatusBarHeight()
      commonActions.setStatusbarHeight(statusBarHeight)
      bootLog(`StatusBar height: ${statusBarHeight}`)
    } catch (e) {
      bootLog('StatusBar height failed, using default 44')
      commonActions.setStatusbarHeight(44)
    }
    try {
      const insets = await getSafeAreaInsets()
      global.lx.safeAreaInsets = insets
    } catch (e) {}
  }

  commonActions.setFontSize(global.lx.fontSize)
  bootLog('Font size changed.')
  const setting = await initSetting()
  bootLog('Setting inited.')

  await initTheme(setting)
  bootLog('Theme inited.')
  await initI18n(setting)
  bootLog('I18n inited.')

  await initUserApi(setting)
  bootLog('User Api inited.')

  setApiSource(setting['common.apiSource'])
  bootLog('Api inited.')

  registerPlaybackService()
  bootLog('Playback Service Registered.')
  await initPlayer(setting)
  bootLog('Player inited.')
  await dataInit(setting)
  bootLog('Data inited.')
  await initCommonState(setting)
  bootLog('Common State inited.')

  void initSync(setting)
  bootLog('Sync inited.')

  isInited ||= true

  return handlePushedHomeScreen
}

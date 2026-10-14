import { NativeEventEmitter, NativeModules, Platform } from 'react-native'

const { UserApiModule } = NativeModules

// iOS 上 UserApiModule 不存在，提供空实现兜底
const SafeUserApiModule = UserApiModule ?? {
  loadScript: () => {},
  sendAction: () => {},
  destroy: () => {},
}

let loadScriptInfo: LX.UserApi.UserApiInfo | null = null

export const loadScript = (info: LX.UserApi.UserApiInfo & { script: string }) => {
  loadScriptInfo = info
  SafeUserApiModule.loadScript({
    id: info.id,
    name: info.name,
    description: info.description,
    version: info.version ?? '',
    author: info.author ?? '',
    homepage: info.homepage ?? '',
    script: info.script,
  })
}

export interface SendResponseParams {
  requestKey: string
  error: string | null
  response: {
    statusCode: number
    statusMessage: string
    headers: Record<string, string>
    body: any
  } | null
}

export interface SendActions {
  request: LX.UserApi.UserApiRequestParams
  response: SendResponseParams
}

export const sendAction = <T extends keyof SendActions>(action: T, data: SendActions[T]) => {
  SafeUserApiModule.sendAction(action, JSON.stringify(data))
}

export interface InitParams {
  status: boolean
  errorMessage: string
  info: LX.UserApi.UserApiInfo
}

export interface ResponseParams {
  status: boolean
  errorMessage?: string
  requestKey: string
  result: any
}

export interface UpdateInfoParams {
  name: string
  log: string
  updateUrl: string
}

export interface RequestParams {
  requestKey: string
  url: string
  options: {
    method: string
    data: any
    timeout: number
    headers: any
    binary: boolean
  }
}

export type CancelRequestParams = string

export interface Actions {
  init: InitParams
  request: RequestParams
  cancelRequest: CancelRequestParams
  response: ResponseParams
  showUpdateAlert: UpdateInfoParams
  log: string
}

export type ActionsEvent = { [K in keyof Actions]: { action: K, data: Actions[K] } }[keyof Actions]

export const onScriptAction = (_handler: (event: ActionsEvent) => void): () => void => {
  // iOS 上 UserApiModule 不存在，返回空取消函数，不创建 NativeEventEmitter
  if (!UserApiModule) return () => {}

  const eventEmitter = new NativeEventEmitter(UserApiModule)
  const eventListener = eventEmitter.addListener('api-action', event => {
    if (event.data) event.data = JSON.parse(event.data as string)
    if (event.action == 'init') {
      if (event.data.info) event.data.info = { ...loadScriptInfo, ...event.data.info }
      else event.data.info = { ...loadScriptInfo }
    } else if (event.action == 'showUpdateAlert') {
      if (!loadScriptInfo?.allowShowUpdateAlert) return
    }
    _handler(event as ActionsEvent)
  })
  return () => {
    eventListener.remove()
  }
}

export const destroy = () => {
  SafeUserApiModule.destroy()
}

import { forwardRef, useCallback, useImperativeHandle, useRef, useState } from 'react'
import { DrawerLayoutAndroid, Platform, View, type LayoutChangeEvent } from 'react-native'
import { usePageVisible } from '@/store/common/hook'
import { type COMPONENT_IDS } from '@/config/constant'

interface Props {
  visibleNavNames: COMPONENT_IDS[]
  widthPercentage: number
  widthPercentageMax?: number
  children?: React.ReactNode
}

export interface DrawerLayoutFixedType {
  openDrawer: () => void
  closeDrawer: () => void
  fixWidth: () => void
}

const DrawerLayoutFixed = forwardRef<DrawerLayoutFixedType, Props>(({ children }, ref) => {
  useImperativeHandle(ref, () => ({
    openDrawer() {},
    closeDrawer() {},
    fixWidth() {},
  }), [])

  // iOS: 直接渲染 children，不使用 DrawerLayoutAndroid
  if (Platform.OS === 'ios') {
    return <View style={{ flex: 1 }}>{children}</View>
  }

  // Android 原有逻辑
  const drawerLayoutRef = useRef<DrawerLayoutAndroid>(null)
  const [w, setW] = useState<number | `${number}%`>('100%')
  const [drawerWidth, setDrawerWidth] = useState(0)
  const changedRef = useRef({ width: 0, changed: false })

  const fixDrawerWidth = useCallback(() => {
    if (!changedRef.current.width) return
    changedRef.current.changed = true
    setW(changedRef.current.width - 1)
  }, [])

  usePageVisible([], useCallback((visible) => {
    if (!visible || !changedRef.current.width) return
    fixDrawerWidth()
  }, [fixDrawerWidth]))

  const handleLayout = useCallback((e: LayoutChangeEvent) => {
    if (changedRef.current.changed) {
      setW('100%')
      changedRef.current.changed = false
    } else {
      const width = e.nativeEvent.layout.width
      if (changedRef.current.width == width) return
      changedRef.current.width = width
      const wp = Math.floor(width * 0.7)
      setDrawerWidth(Math.min(wp, 300))
      changedRef.current.changed = true
      setW(width - 1)
    }
  }, [])

  return (
    <View onLayout={handleLayout} style={{ width: w, flex: 1 }}>
      <DrawerLayoutAndroid ref={drawerLayoutRef} drawerWidth={drawerWidth}>
        <View style={{ marginRight: w == '100%' ? 0 : -1, flex: 1 }}>
          {children}
        </View>
      </DrawerLayoutAndroid>
    </View>
  )
})

export default DrawerLayoutFixed

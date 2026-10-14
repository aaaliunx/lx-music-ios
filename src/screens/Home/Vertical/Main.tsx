import { View } from 'react-native'
import Search from '../Views/Search'
import SongList from '../Views/SongList'
import Mylist from '../Views/Mylist'
import Leaderboard from '../Views/Leaderboard'
import Setting from '../Views/Setting'
import commonState from '@/store/common/state'
import { createStyle } from '@/utils/tools'
import { setNavActiveId } from '@/core/common'
import { useEffect, useState } from 'react'
import type { InitState as CommonState } from '@/store/common/state'

const Main = () => {
  const [activeId, setActiveId] = useState<CommonState['navActiveId']>(commonState.navActiveId)

  useEffect(() => {
    const handleUpdate = (id: CommonState['navActiveId']) => {
      setActiveId(id)
    }
    global.state_event.on('navActiveIdUpdated', handleUpdate)
    return () => {
      global.state_event.off('navActiveIdUpdated', handleUpdate)
    }
  }, [])

  let page: React.ReactNode = null
  switch (activeId) {
    case 'nav_search':
      page = <Search />
      break
    case 'nav_songlist':
      page = <SongList />
      break
    case 'nav_top':
      page = <Leaderboard />
      break
    case 'nav_love':
      page = <Mylist />
      break
    case 'nav_setting':
      page = <Setting />
      break
  }

  return (
    <View style={styles.container}>
      {page}
    </View>
  )
}

const styles = createStyle({
  container: {
    flex: 1,
    overflow: 'hidden',
  },
})

export default Main

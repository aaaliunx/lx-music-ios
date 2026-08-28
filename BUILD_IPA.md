# 把「落雪音乐 / LX Music」编译成 iOS IPA（免费 Apple ID 侧载）

> 前提说明：你电脑里装的是**桌面版（Electron）**，它**无法**直接转成 iOS 安装包。
> 本方案用的是官方移动端 React Native 源码 `lx-music-mobile`（仓库里已自带完整 iOS 工程），
> 在**云端 macOS**上把它编译成**未签名 IPA**，你再用 **Sideloadly + 免费 Apple ID** 侧载到 iPhone。
> 全程**不需要** $99 付费开发者账号。

---

## 方案 A：GitHub Actions 云端编译（推荐，最简单）

### 1. 把这个仓库推到你的 GitHub
这个工程已经准备好了（含 `.github/workflows/build-ios-unsigned.yml`）。
你需要有自己的 GitHub 仓库：

```bash
# 在项目根目录 lx-music-ios/ 下
git remote remove origin            # 去掉官方的只读源
git remote add origin https://github.com/<你的用户名>/lx-music-ios.git
git branch -M main
git push -u origin main
```
> 也可以直接去 github.com 新建空仓库，按上面的命令推上去。

### 2. 触发云端构建
- 进你的 GitHub 仓库 → **Actions** → 左侧选 `Build LX Music iOS (unsigned IPA)` → **Run workflow**。
- 或者只要 `git push` 到 `master`/`main` 就会自动跑。
- 云端用的是 macOS  runner，约 **5–15 分钟**完成（要装 cocoapods + 编译 RN）。

### 3. 下载未签名 IPA
- 构建完成后，在 Actions 页面本次运行的 **Artifacts** 里下载 `luoxue-ios-unsigned`。
- 解压得到 `落雪-unsigned.ipa`。

### 4. 用免费 Apple ID 签名并侧载到 iPhone
1. 电脑装 **Sideloadly**（https://sideloadly.io ），iPhone 用数据线连电脑。
2. Sideloadly 里：
   - IPA 选择刚下载的 `落雪-unsigned.ipa`
   - Apple ID 填你的**免费** Apple 账号
   - 点 **Start** → 输入 Apple ID 密码（首次需在 iPhone 上信任开发者：设置 → 通用 → VPN与设备管理 → 信任）
3. 安装完成，iPhone 上出现「洛雪音乐助手」。
4. ⚠️ 免费账号签名的 App **每 7 天**会失效，用 Sideloadly 重新点一次 Start 续期即可（可勾选「Auto-Refresh」自动续期）。

---

## 方案 B：EAS Build（可选，适合以后买付费账号）

如果你更想用 Expo 的 EAS 云端构建（同样在 macOS 上编译）：

```bash
npm install -g eas-cli
eas login                 # 用 Expo 账号登录（没有就注册，免费）
eas build:configure       # 已为你准备好 eas.json（见下方）
eas build --platform ios --profile development
```
- 免费 Apple ID 可做 development 构建（需先注册设备 UDID）；付费账号可做 production / TestFlight。
- 本仓库已附带一份 `eas.json`（development / preview / production 三个 profile）。

---

## 方案 C：SideStore 自动续签（推荐已装 SideStore / LiveContainer 的用户）

如果你已经装了 **SideStore / LiveContainer**，就完全不用再每 7 天手动续签了。
SideStore 支持**设备端自动续签 + 快捷指令定时触发**。

### 1. 先确保 SideStore 自身能刷新
- iOS **设置 → SideStore**：打开「后台 App 刷新」
- SideStore App 内 **设置**：打开「Background Refresh / 自动刷新」
- 确保 **VPN 通道**处于启用状态：新版用内置的 `LocalDevVPN`，旧版/某些安装包用 `WireGuard`（按你安装时的提示操作）
- 确认 **Anisette 服务器**已填（没有可先用公共地址，如 `https://anisette.jawshoeadan.me/`；若 Apple ID 被锁，建议自建一个）

### 2. 创建自动续签的「个人自动化」快捷指令
1. iPhone 打开 **快捷指令 App** → 底部「自动化」→「创建个人自动化」（或右上角 `+`）
2. 选择 **「特定时间」** → 设为每天某个时间（建议早上 7:00 或你插着充电器的时候）→「下一步」
3. 添加操作：搜索 **「SideStore」** 或 **「Refresh」** → 选择 **「Refresh All Apps」**
4. （可选）在前面加一步 **「设定 VPN」** → 启用 SideStore / WireGuard 配置，确保刷新通道开着
5. 「下一步」→ **关闭「运行前询问」** → 点「不询问」→ 完成

以后每天到点，SideStore 就会自动刷新所有侧载 App（包括 LiveContainer 本体）。

### 3. 注意事项
- 自动刷新时手机需要联网，且**不要开启低电量模式**
- 若失败，先手动打开 SideStore → 点刷新，看是 Anisette 服务器问题还是 VPN 没连
- **LiveContainer 里的 App 不需要单独续签**：只要 LiveContainer 本身签名有效，里面的 App 就能继续用

---

## iOS 26.4+ 特别说明（SideStore 快捷指令报错"功能不属于此版本"）

iOS 26.4 起苹果改了底层网络机制，SideStore 的「Refresh All Apps」**快捷指令动作会失效**，运行时报
"此操作在当前版本不可用 / 不属于此版本"。这是 SideStore 的已知 bug，不是你设置的问题。

### 最稳的替代方案：用「打开 App」绕开坏掉的动作
1. 删掉原来那条报错的自动化
2. 快捷指令 → 自动化 → 创建个人自动化 → 特定时间 → 每天某时
3. 添加操作：**「打开 App」** → 选 **SideStore**
4. 关闭「运行前询问」→ 完成
- 原理：打开 SideStore 会唤醒它的后台刷新守护进程，自动续签，完全不碰坏掉的「Refresh All Apps」意图
- 同时确认 SideStore 设置里「Background Refresh / 后台应用刷新」已开启

### 如果还想用「Refresh All Apps」动作
- 删除该快捷指令/自动化，**重建一次**并重新添加「Refresh All Apps」动作（常是动作残留了旧版本引用导致报错）
- 或直接使用现成模板（把里面的 VPN 变量改成你的 LocalDevVPN）：`https://www.icloud.com/shortcuts/faf5331bf084b45bf86479bddb14a92ac`

### 版本与签名要点
- iOS 26.4+ 之后，**旧版 SideStore 连手动刷新都会失败**。若你在 SideStore → 我的应用 → 点「7 天」手动刷新是成功的，说明只是快捷指令动作的问题，按上面处理即可；若手动也失败，需升级到带 iOS 26.4 修复的 **Nightly/Alpha 版 SideStore**（用 iloader 或 SideStore 源装最新 nightly）。
- 若升级后仍报网络/签名错误：在 LocalDevVPN 设置里把 Tunnel / Device IP 设成你 WiFi 子网里一个空闲 IP（设置 → WiFi → 看 IPv4 地址）。

---

## 关于「音源」
LX Music 本体**不内置曲库**，需要你在 App 内「设置 → 音乐来源」导入第三方音源脚本（网上搜 “LX Music 音源” 即可找到）。
音源的合规性由你自行判断，建议仅用于个人学习试听。

---

## 常见问题
- **构建失败 / Pod 安装报错**：多半是网络或 Ruby 版本问题。可在本地 `cd ios && bundle exec pod install --repo-update` 先验证。
- **Archive 报签名错误**：工作流已用 `CODE_SIGNING_ALLOWED=NO` 关闭签名，正常不会卡在签名；卡在编译则看 Actions 日志里的具体报错。
- **装上打不开**：iPhone 上「设置 → 通用 → VPN与设备管理」里把你的 Apple ID 开发者证书**信任**一下。
- **Flipper 相关编译错误**：在仓库根目录加环境变量 `NO_FLIPPER=1` 重新跑（工作流可改 `env` 段）。
- **打开 App 报错：`react-native-file-system` doesn't seem to be linked**：
  - 根因：**上游 `lyswhut/react-native-file-system` 只有 Android 原生实现，`ios/` 目录是空的**，iOS 端没有 `FileSystemModule` 原生模块，运行时 `NativeModules.FileSystemModule` 为 undefined 就抛这个错。这**不是构建配置问题**（之前把 git+ssh 改 https 的修复只会让它装上"空壳"库，二进制产物一模一样）。
  - 修复：本仓库把 `react-native-file-system` 指向带 iOS 原生实现的 fork `leguagou-debug/react-native-file-system`（commit `63c56f6`，用 `NSFileManager`+`zlib`+`CommonCrypto` 实现了文件操作 / gzip / hash 全套）。重新触发一次构建即可得到真正的 iOS IPA。

---

## 文件说明
- `.github/workflows/build-ios-unsigned.yml` —— 云端 macOS 编译 + 出未签名 IPA 的自动化脚本
- `ios/` —— 官方自带的 iOS 原生工程（xcodeproj + Podfile）
- 源码为官方 `lyswhut/lx-music-mobile`（Apache-2.0）

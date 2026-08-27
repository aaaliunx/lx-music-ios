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
- 构建完成后，在 Actions 页面本次运行的 **Artifacts** 里下载 `LxMusicMobile-unsigned-ipa`。
- 解压得到 `LxMusicMobile-unsigned.ipa`。

### 4. 用免费 Apple ID 签名并侧载到 iPhone
1. 电脑装 **Sideloadly**（https://sideloadly.io ），iPhone 用数据线连电脑。
2. Sideloadly 里：
   - IPA 选择刚下载的 `LxMusicMobile-unsigned.ipa`
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

## 关于「音源」
LX Music 本体**不内置曲库**，需要你在 App 内「设置 → 音乐来源」导入第三方音源脚本（网上搜 “LX Music 音源” 即可找到）。
音源的合规性由你自行判断，建议仅用于个人学习试听。

---

## 常见问题
- **构建失败 / Pod 安装报错**：多半是网络或 Ruby 版本问题。可在本地 `cd ios && bundle exec pod install --repo-update` 先验证。
- **Archive 报签名错误**：工作流已用 `CODE_SIGNING_ALLOWED=NO` 关闭签名，正常不会卡在签名；卡在编译则看 Actions 日志里的具体报错。
- **装上打不开**：iPhone 上「设置 → 通用 → VPN与设备管理」里把你的 Apple ID 开发者证书**信任**一下。
- **Flipper 相关编译错误**：在仓库根目录加环境变量 `NO_FLIPPER=1` 重新跑（工作流可改 `env` 段）。

---

## 文件说明
- `.github/workflows/build-ios-unsigned.yml` —— 云端 macOS 编译 + 出未签名 IPA 的自动化脚本
- `ios/` —— 官方自带的 iOS 原生工程（xcodeproj + Podfile）
- 源码为官方 `lyswhut/lx-music-mobile`（Apache-2.0）

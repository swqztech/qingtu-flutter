# qingtu-flutter（轻图）

本地图片 **压缩** / **横向拼接**，对齐 [qingtu-avalonia](https://github.com/swqztech/qingtu-avalonia)。

## 环境

- Flutter stable（本机 SDK 可放在 `../.flutter`）
- **Windows** / **Android** / **iOS**（同一套 `lib/`）
- Windows 带插件构建需要 **创建符号链接** 权限。任选其一：
  1. **设置** → **隐私和安全性** → **开发人员模式** → 打开  
  2. 或以**管理员** PowerShell 执行一次（本机已用此方式修好）：
     ```powershell
     New-Item -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock -Force
     Set-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock AllowDevelopmentWithoutDevLicense 1
     ```
  改完后**新开一个终端**再 `flutter run`。

## 运行

```bash
cd qingtu-flutter
flutter pub get
flutter run -d windows
flutter run -d android   # 需 Android SDK / 设备
flutter run -d ios       # 需 macOS + Xcode
```

## 打包（绿色 zip + NSIS）

```bash
bash packaging/build.sh
# dist/轻图-flutter-<版本>-win64-绿色版.zip
# dist/轻图-flutter-<版本>-win64-setup.exe
```

仅 zip：`INSTALLER=portable bash packaging/build.sh`

## 功能

- 多图选择、质量/最长边/输出格式（保持原格式 / JPEG / PNG / WebP）
- 自定义输出目录
- 横向拼接 → `stitched.png`（输出到 `compressed` 或自定义目录）

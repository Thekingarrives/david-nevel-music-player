# DavidNevel 大卫的竖琴 


因为喜欢听音乐  喜欢简洁
自己 CodeBuddy了一个播放器 功能很简单 好在简洁
喜欢有人欣赏 指出不足。随时改进！ 

感谢！！！



<img width="1200" height="796" alt="Screenshot 2026-04-28 at 12 42 28 — Thekingarrives-david-nevel-music-player- A simple and elegant macOS local music player built with Swift" src="https://github.com/user-attachments/assets/148516f2-8343-49c4-bb6f-3e009dc47e3f" />
<img width="1200" height="796" alt="Screenshot 2026-04-28 at 12 42 43 — David Nevel" src="https://github.com/user-attachments/assets/5f1470fc-9b93-4af4-be43-e8b374cc33e8" />

一款简洁优雅的 macOS 本地音乐播放器，使用 Swift 和 Cocoa 原生开发。

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

> ⚠️ **免责声明**：本项目仅供学习参考，按"现状"提供，使用风险自负。详见 [DISCLAIMER.md](DISCLAIMER.md)。

## 功能特性

- 拖放文件夹快速导入音乐
- 支持 MP3、M4A、AAC、WAV、AIFF、FLAC、OGG、WMA 格式
- 文件夹分类管理，支持自定义颜色
- 用户歌单（收藏夹）功能
- 多种播放模式：顺序播放、列表循环、单曲循环、随机播放
- 歌曲排序：按名称、时长、大小、格式
- 倒计时自动关闭
- 简洁直观的原生 macOS 界面

## 系统要求

- macOS 13.0 或更高版本
- Apple Silicon 或 Intel Mac

## 安装使用

### 方式一：直接运行

```bash
# 克隆仓库
git clone https://github.com/Thekingarrives/david-nevel-music-player.git
cd david-nevel-music-player

# 编译运行
swift Sources/main.swift
```

### 方式二：构建应用

```bash
# 使用构建脚本
./Scripts/build.sh

# 构建完成后，应用位于 Build/SimpleMusicPlayer.app
open Build/SimpleMusicPlayer.app
```

### 方式三：Xcode 打开

双击 `SimpleMusicPlayer.xcodeproj` 使用 Xcode 打开并运行。

## 使用说明

1. **导入音乐**：将音乐文件夹拖入应用窗口
2. **切换文件夹**：点击左侧文件夹列表
3. **播放控制**：点击歌曲或使用底部播放按钮
4. **创建歌单**：右键左侧文件夹区域 → 新建歌单
5. **收藏歌曲**：右键歌曲 → 收藏到歌单
6. **排序**：点击列表表头（名称/大小/时长/格式）
7. **自动关闭**：点击右上角倒计时设置

## 项目结构

```
.
├── Sources/
│   └── main.swift          # 主程序源码
├── Resources/
│   ├── AppIcon.iconset/    # 应用图标
│   └── generate_icon.py    # 图标生成脚本
├── Scripts/
│   └── build.sh            # 构建脚本
├── Info.plist              # 应用配置
└── README.md               # 本文件
```

## 技术栈

- **语言**：Swift 5
- **框架**：Cocoa、AVFoundation、Combine
- **最低版本**：macOS 13.0

## 开源协议

本项目采用 [MIT License](LICENSE) 开源协议。

## 致谢

感谢使用 David Nevel Music Player！欢迎提交 Issue 和 Pull Request。

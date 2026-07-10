<!-- markdownlint-disable MD033 MD041 -->
<div align="center">

# 🪐 物理沙盒 · Physics Sandbox

[![HarmonyOS](https://img.shields.io/badge/HarmonyOS-NEXT-blue?logo=harmonyos)](https://developer.huawei.com/consumer/cn/harmonyos/)
[![SDK](https://img.shields.io/badge/SDK-6.1.0(23)-brightgreen)](https://developer.huawei.com/consumer/cn/harmonyos/)
[![Language](https://img.shields.io/badge/Language-ArkTS-3178C6?logo=typescript)](https://developer.huawei.com/consumer/cn/arkts/)
[![License](https://img.shields.io/badge/License-MIT-green)](./LICENSE)
[![Stars](https://img.shields.io/github/stars/Gengineer-26/openHarmony?style=social)](https://github.com/Gengineer-26/openHarmony)

**基于 HarmonyOS 的 2D 物理仿真与创作工具**

自由绘制几何体 · 真实物理交互 · 场景保存与分享

</div>

---

## 📸 预览

> 🔜 截图即将更新（请在 AppScope/resources 中放入应用截图）

| 物理画布 | 场景管理 | 知识库 |
|:---:|:---:|:---:|
| ![画布](screenshots/canvas.png) | ![场景](screenshots/scenes.png) | ![知识库](screenshots/knowledge.png) |

---

## ✨ 功能特性

### 🔧 绘图工具
| 工具 | 说明 |
|------|------|
| ⭕ 圆形 \| ⬜ 矩形 \| 🔺 三角形 | 绘制基础几何刚体 |
| 🔗 弹簧 | 弹性力连接两个物体 |
| 🪢 绳索 | 限制两物体间最大距离 |
| 🔩 铰链 | 创建旋转关节 |
| 🏗️ 连杆 | 固定距离的刚性连接 |
| ⚓ 锚点 | 将物体固定在空间中 |
| ✏️ 橡皮擦 | 删除物体 |

### 🧲 物理引擎
- 重力方向 & 大小可调 · 质量 / 摩擦 / 弹性系数
- 运动轨迹可视化 · 仿真速度实时调节
- 自研 2D 引擎 (Box2D-like)

### 🎯 布尔运算
- **并集** Union — 合并图形 · **差集** Subtract · **交集** Intersect

### 💾 场景管理
- 保存 / 加载本地场景 · JSON 导入导出
- 跨设备分享（系统分享 / Deep Link）

### 👤 用户系统
- 注册 / 登录 · 登录状态持久化

### 📚 知识库 & 教程
- 每日物理知识推送 · 离线百科 · 内置图文教程

---

## 🛠️ 技术栈

| 技术 | 说明 |
|------|------|
| 平台 | HarmonyOS NEXT (API 23) |
| 语言 | ArkTS |
| SDK | 6.1.0 (23) |
| 架构 | MVVM |
| 物理引擎 | 自研 2D (Box2D-like) |
| 持久化 | KVStore (分布式) + Preferences |
| 跨设备 | Distributed Data Sync + System Share |

---

## 📁 项目结构

```
├── AppScope/                 # 应用全局配置
├── entry/                    # 主模块
│   └── src/main/ets/
│       ├── common/           # 常量 & 主题
│       ├── components/       # UI 组件
│       ├── entryability/     # 应用入口
│       ├── model/            # 数据模型 & 类型
│       ├── pages/            # 页面
│       ├── physics/          # 物理引擎核心
│       ├── utils/            # 工具类
│       └── viewmodel/        # 状态管理
├── hvigor/                   # 构建配置
├── build-profile.json5.example  # 签名配置模板
└── oh-package.json5          # 包依赖
```

---

## 🚀 快速开始

### 环境要求
- DevEco Studio 5.0+
- HarmonyOS SDK API 23 (6.1.0)
- 设备：HarmonyOS NEXT 手机 / 平板 / 2合1（或模拟器）

### 运行

```bash
# 克隆
git clone https://github.com/Gengineer-26/openHarmony.git

# 复制签名配置模板（填入你的签名信息）
cp build-profile.json5.example build-profile.json5
```

然后用 DevEco Studio 打开项目 → 同步依赖 → Run。

---

## 🤝 参与贡献

欢迎提交 Issue 和 PR！

1. Fork 本仓库
2. 创建特性分支：`git checkout -b feat/amazing-feature`
3. 提交改动：`git commit -m 'feat: add amazing feature'`
4. 推送到分支：`git push origin feat/amazing-feature`
5. 发起 Pull Request

---

## 📄 License

本项目基于 [MIT License](./LICENSE) 开源。

---

<div align="center">

⭐ **如果这个项目对你有帮助，请给一个 Star！** ⭐

</div>

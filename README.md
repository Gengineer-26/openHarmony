# 🎨 物理沙盒 · Physics Sandbox

> 一款基于 **HarmonyOS** 的 2D 物理仿真与创作工具，支持自由绘制几何体、物理交互模拟、场景管理及跨设备分享。

---

## ✨ 功能特性

### 🔧 丰富的绘图工具
| 工具 | 说明 |
|------|------|
| ⭕ 圆形 | 绘制圆形刚体 |
| ⬜ 矩形 | 绘制矩形刚体 |
| 🔺 三角形 | 绘制三角形刚体 |
| 🔗 弹簧 | 连接两个物体并产生弹性力 |
| 🪢 绳索 | 限制两个物体之间的最大距离 |
| 🔩 铰链 | 创建旋转关节 |
| 🏗️ 连杆 | 固定距离的刚性连接 |
| ⚓ 锚点 | 将物体固定在空间中的某一点 |
| ✏️ 橡皮擦 | 删除物体 |

### 🧲 物理引擎
- 真实的重力模拟（方向和大小可调）
- 质量、摩擦力、弹性系数等物理属性
- 速度、角速度展示
- 运动轨迹可视化
- 仿真速度实时调节

### 🎯 布尔运算
- **并集 (Union)** — 合并两个图形
- **差集 (Subtract)** — 从一个图形中减去另一个
- **交集 (Intersect)** — 保留两图形重叠部分

### 💾 场景管理
- 保存当前场景到本地
- 加载历史场景
- 场景跨设备分享（系统分享 / Deep Link）
- 支持场景 JSON 导入导出

### 👤 用户系统
- 注册 / 登录
- 个人主页
- 登录状态持久化（重启应用保持登录）

### 📚 知识库
- 每日物理知识推送
- 内置物理知识百科（力学、运动学等）
- 支持离线浏览

### 📖 使用教程
- 内置图文教程，快速上手

---

## 🛠️ 技术栈

| 技术 | 说明 |
|------|------|
| **平台** | HarmonyOS NEXT (API 23) |
| **语言** | ArkTS (TypeScript 超集) |
| **SDK** | 6.1.0 (23) |
| **架构** | MVVM (Model-View-ViewModel) |
| **物理引擎** | 自研 2D 物理引擎 (Box2D-like) |
| **数据持久化** | KVStore (分布式) + Preferences |
| **网络** | HTTP 请求 + 离线回退 |
| **跨设备** | Distributed Data Sync + System Share |

---

## 📁 项目结构

```
MyApplication7.1/
├── AppScope/                    # 应用全局配置
│   └── resources/
├── entry/                       # 主模块
│   └── src/main/
│       ├── ets/
│       │   ├── common/          # 常量 & 主题
│       │   ├── components/      # UI 组件
│       │   ├── entryability/    # 应用入口
│       │   ├── model/           # 数据模型 & 类型
│       │   ├── pages/           # 页面（主画布/登录/注册/个人中心）
│       │   ├── physics/         # 物理引擎核心
│       │   ├── utils/           # 工具类（认证/数据库/网络/存储/撤销管理）
│       │   └── viewmodel/       # 状态管理
│       └── resources/           # 资源文件
├── hvigor/                      # 构建配置
├── build-profile.json5          # 项目构建配置
└── oh-package.json5             # 包依赖
```

---

## 🚀 快速开始

### 环境要求

- **DevEco Studio** 5.0+
- **HarmonyOS SDK** API 23 (6.1.0)
- **设备**：HarmonyOS NEXT 手机 / 平板 / 2合1设备（或模拟器）

### 运行步骤

1. 克隆仓库
   ```bash
   git clone https://github.com/Gengineer-26/openHarmony.git
   ```

2. 用 DevEco Studio 打开项目目录

3. 同步依赖 & 构建
   ```
   Build → Build Project
   ```

4. 运行到设备或模拟器
   ```
   Run → Run 'entry'
   ```

---

## 🏗️ 构建

```bash
# Debug 构建
hvigorw assembleHap --mode module -p product=default -p buildMode=debug

# Release 构建
hvigorw assembleHap --mode module -p product=default -p buildMode=release
```

---

## 📋 权限说明

| 权限 | 用途 |
|------|------|
| `ohos.permission.INTERNET` | 获取每日物理知识、网络数据 |
| `ohos.permission.DISTRIBUTED_DATASYNC` | 跨设备场景同步与分享 |

---

## 📝 待办事项

- [ ] 物理引擎升级（流体模拟）
- [ ] 更多图形工具（多边形、贝塞尔曲线）
- [ ] 场景云端同步
- [ ] 社区场景广场
- [ ] 夜间模式

---

## 📄 License

本项目仅供学习交流使用。

---

> 🧪 *Let curiosity shape your world — one physics body at a time.*

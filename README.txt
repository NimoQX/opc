MyQLH OpenClaw - 轻量版
========================

类型: 纯净便携版，无加密验证
基于: OpenClaw 2026.3.24

快速上手
--------

1. 双击 ai-setup.bat → 配置 AI 提供商
2. 双击 启动.bat  → 启动服务
3. 访问 http://localhost:1620

首次启动后，按界面引导完成初始化。

文件说明
--------

├── 启动.bat          # 主启动脚本（含自检）
├── ai-setup.bat      # AI 配置入口
├── ai-setup.ps1      # AI 配置工具
├── app\              # 应用程序
│   ├── core\        # OpenClaw 核心 + 依赖
│   └── runtime\     # Node.js 运行时
└── data\            # 数据目录
    └── .openclaw\   # 配置 + 工作区

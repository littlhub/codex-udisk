# codex-udisk

Codex CLI 便携版（Windows x64）—— 解压即用，不需要安装 Node.js 或 npm。

- **上游版本**：`codex` `0.155.1`
- **目标平台**：`x86_64-pc-windows-msvc`
- **打包形态**：便携目录（portable），所有依赖随包分发

## 下载

二进制体积较大（压缩后约 134 MB），因此**不放在仓库文件树里**，请从 Releases 下载：

**[→ 前往 Releases 下载 `codex-udisk.zip`](../../releases/latest)**

## 使用

1. 下载并解压 `codex-udisk.zip` 到任意目录（例如 `D:\codex-udisk`）
2. **先配置 API Key**（见下节）
3. 双击 `codex.bat` 启动

停止所有 Codex 相关进程：双击 `stop.bat`。

## 配置 API Key

出于安全考虑，仓库中的 `codex.bat` **不包含任何密钥**（`OPENAI_API_KEY` 为空）。

首次使用需要自己创建 `codex-home` 目录并放入配置文件：

```bat
mkdir codex-home
```

然后创建 `codex-home\auth.json`：

```json
{
  "auth_mode": "apikey",
  "OPENAI_API_KEY": "你的密钥"
}
```

以及 `codex-home\config.toml`：

```toml
openai_base_url = "https://apihub.agnes-ai.cn/v1"
model_provider = "agnes"

[provider]
model = "agnes-2.5-flash"
max_tokens = 512000

web_search = "disabled"

[features]
multi_agent = false
multi_agent_v2 = false

[auth]
mode = "apikey"
openai_api_key = ""

[model_providers.agnes]
name = "Agnes AI"
base_url = "https://apihub.agnes-ai.cn/v1"
supports_websockets = false
websocket_connect_timeout_ms = 1000
env_key = "OPENAI_API_KEY"
```

也支持用环境变量注入，不必写进文件：

```bat
set "OPENAI_API_KEY=你的密钥"
codex.bat
```

> ⚠️ **不要把密钥提交到 Git 仓库。** 若曾提交过，请立即到服务商后台作废并重新签发。

## 目录结构

```
codex-udisk/
├─ codex.bat                          启动脚本
├─ stop.bat                           停止脚本
├─ codex-bin/
│  ├─ bin/
│  │  ├─ codex.exe                    主程序
│  │  └─ codex-code-mode-host.exe
│  ├─ codex-path/
│  │  └─ rg.exe                       内置 ripgrep
│  ├─ codex-resources/
│  │  ├─ codex-command-runner.exe
│  │  └─ codex-windows-sandbox-setup.exe
│  └─ codex-package.json              打包元数据（版本 / 目标平台）
└─ codex-home/                        运行时数据（首次运行自动生成，不随仓库分发）
```

## 说明

- `codex-home/` 是**本机运行时目录**，存放登录凭据、会话记录、日志与 SQLite 状态库。
  它**不会**出现在本仓库中，也不应上传到任何公开位置。
- `codex-windows-sandbox-setup.exe` 用于配置 Windows 沙箱环境，部分功能依赖它。
- 本仓库只分发打包产物，不包含 Codex 上游源代码。上游项目与许可请见其官方仓库。

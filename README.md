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
2. **先配置厂商**：双击 `configure.bat`，按提示填 API Key（见下节）
3. 双击 `codex.bat` 启动

停止所有 Codex 相关进程：双击 `stop.bat`。

## 配置厂商

出于安全考虑，仓库中的 `codex.bat` **不包含任何密钥**（`OPENAI_API_KEY` 为空）。

`codex.bat` 启动前会检查 `codex-home\` 下的 `auth.json` 与 `config.toml`，缺一个就直接退出。而这个目录不随仓库分发，所以首次使用必须先创建。

**推荐：双击 `configure.bat`**，它会建目录并写好两份配置：

```
  ============================================
    codex-udisk  厂商配置
  ============================================

  API Key : sk-xxxxxxxxxxxxxxxx
  API 地址 [默认 https://apihub.agnes-ai.cn/v1] :
  模型名   [默认 agnes-2.5-flash] :

  [1/3] 已创建 codex-home\
  [2/3] 已写入 codex-home\auth.json
  [3/3] 已写入 codex-home\config.toml

  [OK] 配置齐全，双击 codex.bat 即可启动。
```

也可以直接带参数（适合批量部署或写脚本）：

```bat
configure.bat                              交互式，一路回车用默认值
configure.bat <key>                        只给 key，其余用默认
configure.bat <key> <url> <model>          全部指定
configure.bat <key> <url> <model> <provider名>
```

几个细节：

- **provider 名会自动推导**，不用自己想。`apihub.agnes-ai.cn` → `agnes`、`api.deepseek.com` → `deepseek`、`127.0.0.1` → `local`；认不出来的域名取主机名首段（`9router.io` → `p9router`）。它必须与 `model_provider` 和 `[model_providers.X]` 三处一致，手写容易对不上。
- **地址末尾的斜杠会被去掉**，否则会拼成 `//chat/completions`，部分服务端返回 404。
- **重复运行是覆盖，不会堆积**。想换服务商，重跑一次即可。
- **换别的厂商**：接口兼容 OpenAI 就行，填对方的 URL 与模型名。

### 手工配置（不想用脚本时）

```bat
mkdir codex-home
```

创建 `codex-home\auth.json`：

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

### 用环境变量注入

也可以不写文件，直接给环境变量：

```bat
set "OPENAI_API_KEY=你的密钥"
codex.bat
```

### 校验配置

`verify.cjs` 用来检查生成的两份配置是否自洽（provider 名三处一致、地址无多余斜杠、JSON 合法等）：

```bat
node verify.cjs .
```

需要本机有 Node.js。正常输出：

```
  ✓ auth.json 是合法 JSON
  ✓ model_provider 与 [model_providers.X] 一致
  ✓ 地址末尾没有多余斜杠（会拼成 //chat/completions）
  ...
通过：8 项
```

> ⚠️ **不要把密钥提交到 Git 仓库。** 若曾提交过，请立即到服务商后台作废并重新签发。

## 目录结构

```
codex-udisk/
├─ codex.bat                          启动脚本
├─ configure.bat                      一键配置厂商（URL / key / model）
├─ verify.cjs                         校验生成的配置是否自洽
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
└─ codex-home/                        运行时数据（configure.bat 创建，不随仓库分发）
```

## 说明

- `codex-home/` 是**本机运行时目录**，存放登录凭据、会话记录、日志与 SQLite 状态库。
  它**不会**出现在本仓库中，也不应上传到任何公开位置。
- `codex-windows-sandbox-setup.exe` 用于配置 Windows 沙箱环境，部分功能依赖它。
- 本仓库只分发打包产物，不包含 Codex 上游源代码。上游项目与许可请见其官方仓库。

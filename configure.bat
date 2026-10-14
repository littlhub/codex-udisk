@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
cd /d "%~dp0"

rem ============================================================
rem  configure.bat —— 一键配置 codex-udisk 的厂商（URL / key / model）
rem
rem  为什么需要它：codex.bat 启动前会检查 codex-home 下的 auth.json 与
rem  config.toml，缺一个就直接退出。而 codex-home/ 被 .gitignore 排除、
rem  解压包里也没有，所以每个新用户都得手写这两个文件。
rem  这个脚本把「建目录 + 写两份配置」一次做完。
rem
rem  用法：
rem    configure.bat                          交互式填写（推荐）
rem    configure.bat <key>                    只给 key，其余用默认
rem    configure.bat <key> <url> <model>      全部指定
rem
rem  默认值来自仓库 README 里的 Agnes AI 配置。
rem ============================================================

rem ---- 默认值（可被参数或交互覆盖）----
set "DEF_URL=https://apihub.agnes-ai.cn/v1"
set "DEF_MODEL=agnes-2.5-flash"
set "DEF_MAX_TOKENS=512000"

set "KEY=%~1"
set "URL=%~2"
set "MODEL=%~3"
rem provider 名可选（第 4 个参数）。它必须与 [model_providers.X] 的 X 以及
rem model_provider 的值三处一致；写死成 agnes 的话，换成别的服务商就对不上。
set "PROV=%~4"

echo.
echo   ============================================
echo     codex-udisk  厂商配置
echo   ============================================
echo.

rem ---- 0. 确认这是 codex-udisk 目录 ----
if not exist "codex.bat" (
  echo   [x] 当前目录没有 codex.bat
  echo       请把本脚本放到 codex-udisk 根目录（和 codex.bat 同级）再运行。
  echo       当前目录：%CD%
  echo.
  pause
  exit /b 1
)

rem ---- 1. 交互式收集 ----
if "%KEY%"=="" (
  echo   API Key：从服务商后台复制，通常以 sk- 开头。
  echo   注意：粘贴时窗口不会显示字符，这是正常的，粘完按回车即可。
  echo.
  set /p "KEY=  API Key : "
)

rem 去掉用户可能带上的引号与首尾空格
set "KEY=%KEY:"=%"
for /f "tokens=* delims= " %%A in ("!KEY!") do set "KEY=%%A"

if "!KEY!"=="" (
  echo.
  echo   [x] 没有填 Key。没有 Key 的话 codex 启动后会立刻报鉴权失败。
  echo.
  pause
  exit /b 1
)

if "%URL%"=="" (
  set /p "URL=  API 地址 [默认 !DEF_URL!] : "
  if "!URL!"=="" set "URL=!DEF_URL!"
)
if "%MODEL%"=="" (
  set /p "MODEL=  模型名   [默认 !DEF_MODEL!] : "
  if "!MODEL!"=="" set "MODEL=!DEF_MODEL!"
)

rem 地址末尾的斜杠统一去掉：codex 会自己拼 /chat/completions，
rem 留着会变成 //chat/completions，部分服务端会 404。
if "!URL:~-1!"=="/" set "URL=!URL:~0,-1!"

rem ---- provider 名：没给就按地址推导 ----
rem 只有字母数字，且不能以数字开头（TOML 的裸键 / codex 的标识符都这样要求）。
if "!PROV!"=="" call :derive_provider "!URL!"

echo.
echo   --------------------------------------------
echo   将写入以下配置：
echo     API 地址 : !URL!
echo     模型     : !MODEL!
echo     provider : !PROV!
echo     Key      : !KEY:~0,6!...!KEY:~-4!   ^(已打码^)
echo   --------------------------------------------
echo.

rem ---- 2. 建目录 ----
if not exist "codex-home" (
  mkdir "codex-home"
  if errorlevel 1 (
    echo   [x] 无法创建 codex-home 目录（可能没有写权限）
    echo       如果程序放在 C:\Program Files 下，请换到普通目录再试。
    pause
    exit /b 1
  )
  echo   [1/3] 已创建 codex-home\
) else (
  echo   [1/3] codex-home\ 已存在
)

rem ---- 3. 写 auth.json ----
rem 用 > 覆盖而不是 >> 追加：重复运行本脚本时不该堆出多份 JSON。
> "codex-home\auth.json" echo {
>> "codex-home\auth.json" echo   "auth_mode": "apikey",
>> "codex-home\auth.json" echo   "OPENAI_API_KEY": "!KEY!"
>> "codex-home\auth.json" echo }
echo   [2/3] 已写入 codex-home\auth.json

rem ---- 4. 写 config.toml ----
rem 字段与 README 里给出的样例保持一致（openai_base_url / model_provider
rem / [provider] / [model_providers.*] / [auth]）。
> "codex-home\config.toml" echo openai_base_url = "!URL!"
>> "codex-home\config.toml" echo model_provider = "!PROV!"
>> "codex-home\config.toml" echo.
>> "codex-home\config.toml" echo [provider]
>> "codex-home\config.toml" echo model = "!MODEL!"
>> "codex-home\config.toml" echo max_tokens = !DEF_MAX_TOKENS!
>> "codex-home\config.toml" echo.
>> "codex-home\config.toml" echo web_search = "disabled"
>> "codex-home\config.toml" echo.
>> "codex-home\config.toml" echo [features]
>> "codex-home\config.toml" echo multi_agent = false
>> "codex-home\config.toml" echo multi_agent_v2 = false
>> "codex-home\config.toml" echo.
>> "codex-home\config.toml" echo [auth]
>> "codex-home\config.toml" echo mode = "apikey"
>> "codex-home\config.toml" echo openai_api_key = ""
>> "codex-home\config.toml" echo.
>> "codex-home\config.toml" echo [model_providers.!PROV!]
>> "codex-home\config.toml" echo name = "!PROV!"
>> "codex-home\config.toml" echo base_url = "!URL!"
>> "codex-home\config.toml" echo supports_websockets = false
>> "codex-home\config.toml" echo websocket_connect_timeout_ms = 1000
>> "codex-home\config.toml" echo env_key = "OPENAI_API_KEY"
echo   [3/3] 已写入 codex-home\config.toml

goto :done

rem ------------------------------------------------------------
rem  从 URL 推导 provider 名。
rem  取主机名的第一段并去掉非字母数字：apihub.agnes-ai.cn -> apihub
rem  完全取不到时退回 "custom"，保证 [model_providers.X] 一定有合法键名。
rem ------------------------------------------------------------
:derive_provider
set "HOST=%~1"
set "HOST=!HOST:https://=!"
set "HOST=!HOST:http://=!"
for /f "tokens=1 delims=/:." %%A in ("!HOST!") do set "SEG=%%A"
set "SEG=!SEG:-=!"
set "SEG=!SEG:_=!"
rem 常见厂商给个辨识度高的名字。纯按主机名推导会得到 api / p127 这种，
rem 在 [model_providers.api] 里看不出是哪一家。
for %%K in (agnes deepseek openai anthropic moonshot dashscope) do (
  echo !HOST!|findstr /i /c:"%%K" >nul && set "SEG=%%K"
)
echo !HOST!|findstr /i /c:"localhost" >nul && set "SEG=local"
echo !HOST!|findstr /i /c:"127.0.0.1" >nul && set "SEG=local"
rem 去掉可能残留的数字开头（TOML 裸键不能以数字打头）
set "FIRST=!SEG:~0,1!"
echo !FIRST!|findstr /r "^[0-9]$" >nul && set "SEG=p!SEG!"
if "!SEG!"=="" set "SEG=custom"
set "PROV=!SEG!"
exit /b 0

:done

rem ---- 5. 自检：确认关键文件都在 ----
echo.
echo   --------------------------------------------
set "MISSING="
if not exist "codex-home\auth.json" set "MISSING=!MISSING! auth.json"
if not exist "codex-home\config.toml" set "MISSING=!MISSING! config.toml"
if not exist "codex-bin\bin\codex.exe" (
  if not exist "bin\codex.exe" set "MISSING=!MISSING! codex.exe"
)

if not "!MISSING!"=="" (
  echo   [!] 还缺：!MISSING!
  if "!MISSING!"==" codex.exe" (
    echo       codex.exe 不在仓库里，需从 Releases 下载 codex-udisk.zip
    echo       并完整解压后再运行本脚本。单靠 git clone 是跑不起来的。
  )
) else (
  echo   [OK] 配置齐全，双击 codex.bat 即可启动。
)
echo   --------------------------------------------
echo.
echo   配置内容（key 已打码）：
echo.
echo     codex-home\auth.json
echo       OPENAI_API_KEY = !KEY:~0,6!...!KEY:~-4!
echo.
echo     codex-home\config.toml
echo       openai_base_url = !URL!
echo       model           = !MODEL!
echo.
echo   想改配置：重新运行本脚本即可（会覆盖，不会堆积）。
echo   换一家服务商：把 URL 与模型名换成对方的即可，接口需兼容 OpenAI。
echo.
pause

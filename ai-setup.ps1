<#
.SYNOPSIS
  OpenClaw AI Provider Configuration Tool
.DESCRIPTION
  Interactive script to configure AI providers for OpenClaw.
  Supports DeepSeek, Xiaomi MiMo, Volcengine (Doubao), and custom OpenAI-compatible APIs.
#>

# ========== Paths ==========
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ScriptRoot "data\.openclaw\openclaw.json"
$NodeExe = Join-Path $ScriptRoot "app\runtime\node-win-x64\node.exe"
$ClawEntry = Join-Path $ScriptRoot "app\core\node_modules\openclaw\openclaw.mjs"

# ========== Console ==========
$Host.UI.RawUI.BackgroundColor = "Black"
Clear-Host

function Write-Title {
    param([string]$Text)
    Write-Host ""
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Host ""
}

function Write-MenuItem {
    param([int]$Num, [string]$Text, [string]$Desc = "")
    Write-Host "  [$Num] " -ForegroundColor Yellow -NoNewline
    Write-Host "$Text" -ForegroundColor White
    if ($Desc) { Write-Host "       $Desc" -ForegroundColor DarkGray }
}

function Wait-And-Exit {
    Write-Host ""
    Write-Host "Press Enter to exit..." -ForegroundColor DarkGray
    Read-Host
    exit
}

function Read-ApiKey {
    param([string]$Prompt)
    Write-Host ""
    Write-Host $Prompt -ForegroundColor Cyan
    $key = Read-Host "Enter API Key"
    return $key.Trim()
}

function Test-ConfigFile {
    if (-not (Test-Path $ConfigPath)) {
        Write-Host "Config file not found, creating new one..." -ForegroundColor Yellow
        $baseConfig = @{
            gateway = @{
                auth = @{
                    mode = "none"
                }
            }
        }
        $dir = Split-Path $ConfigPath -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $baseConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
    }
}

function Build-ProviderConfig {
    param(
        [string]$Name,
        [string]$BaseUrl,
        [string]$Api,
        [string]$ApiKey,
        [string]$ModelId,
        [string]$ModelName,
        [int]$ContextWindow,
        [int]$MaxTokens,
        [bool]$Reasoning = $false
    )

    $models = @(
        @{
            id = $ModelId
            name = $ModelName
            reasoning = $Reasoning
            input = @("text")
            cost = @{
                input = 0
                output = 0
                cacheRead = 0
                cacheWrite = 0
            }
            contextWindow = $ContextWindow
            maxTokens = $MaxTokens
        }
    )

    return @{
        baseUrl = $BaseUrl
        apiKey = $ApiKey
        api = $Api
        models = $models
    }
}

# ================================
#  Main Menu
# ================================
Write-Title "OpenClaw AI Config Tool"
Write-Host "  Target: $ScriptRoot" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  Select AI Provider:" -ForegroundColor White
Write-Host ""
Write-MenuItem 1 "DeepSeek"       "Model: deepseek-chat / deepseek-reasoner"
Write-MenuItem 2 "Xiaomi MiMo"    "Xiaomi AI large model"
Write-MenuItem 3 "Volcengine"     "ByteDance Volcengine - Doubao models"
Write-MenuItem 4 "Custom OpenAI Compatible" "Any OpenAI API compatible provider"
Write-MenuItem 5 "Local Model"    "Ollama / LM Studio / vLLM / any local API"
Write-Host ""
Write-MenuItem 0 "Exit"           ""
Write-Host ""
$choice = Read-Host "Enter option (0-4)"

switch ($choice) {
    "0" { exit }

    "1" {
        # DeepSeek
        Clear-Host
        Write-Title "DeepSeek Configuration"
        Write-Host "  Website: https://platform.deepseek.com" -ForegroundColor DarkGray
        Write-Host "  Docs: https://api-docs.deepseek.com" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Select DeepSeek model:" -ForegroundColor White
        Write-Host "  [1] deepseek-v4-flash    (Default, fast & capable)" -ForegroundColor White
        Write-Host "  [2] deepseek-v4-pro      (Enhanced reasoning)" -ForegroundColor White
        Write-Host "  [3] deepseek-chat        (Legacy, deprecated 2026-07-24)" -ForegroundColor DarkGray
        Write-Host "  [4] deepseek-reasoner    (Legacy R1, deprecated 2026-07-24)" -ForegroundColor DarkGray
        Write-Host ""
        $modelChoice = Read-Host "Select (1-4, default 1)"
        if ($modelChoice -eq "") { $modelChoice = "1" }

        $apiKey = Read-ApiKey "Enter your DeepSeek API Key (from platform.deepseek.com)"
        if ([string]::IsNullOrEmpty($apiKey)) { Write-Host "API Key cannot be empty!" -ForegroundColor Red; Wait-And-Exit }

        $modelMap = @{
            "1" = @{ id = "deepseek-v4-flash";   name = "deepseek-v4-flash";   reasoning = $true;  ctx = 128000; tokens = 8192 }
            "2" = @{ id = "deepseek-v4-pro";     name = "deepseek-v4-pro";     reasoning = $true;  ctx = 128000; tokens = 8192 }
            "3" = @{ id = "deepseek-chat";       name = "deepseek-chat";       reasoning = $false; ctx = 128000; tokens = 8192 }
            "4" = @{ id = "deepseek-reasoner";   name = "deepseek-reasoner";   reasoning = $true;  ctx = 64000;  tokens = 8192 }
        }
        $m = $modelMap[$modelChoice]

        $providerConfig = Build-ProviderConfig -Name "deepseek" `
            -BaseUrl "https://api.deepseek.com/v1" `
            -Api "openai-completions" `
            -ApiKey $apiKey `
            -ModelId $m.id `
            -ModelName $m.name `
            -ContextWindow $m.ctx `
            -MaxTokens $m.tokens `
            -Reasoning $m.reasoning

        $providerName = "deepseek"
        $providerLabel = "DeepSeek"
    }

    "2" {
        # Xiaomi MiMo
        Clear-Host
        Write-Title "Xiaomi MiMo Configuration"
        Write-Host "  Website: https://token-plan-cn.xiaomimimo.com" -ForegroundColor DarkGray
        Write-Host "  If the presets dont work, choose [0] and type the exact model name" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Select MiMo model:" -ForegroundColor White
        Write-Host "  [1] mimo-v2.5-pro         (Latest pro version)" -ForegroundColor White
        Write-Host "  [2] mimo-v2.5             (Standard v2.5)" -ForegroundColor White
        Write-Host "  [3] mimo-v2.5-tts-voiceclone" -ForegroundColor White
        Write-Host "  [4] mimo-v2.5-tts-voicedesign" -ForegroundColor White
        Write-Host "  [5] mimo-v2.5-tts" -ForegroundColor White
        Write-Host "  [6] mimo-v2-pro" -ForegroundColor White
        Write-Host "  [7] mimo-v2-omni" -ForegroundColor White
        Write-Host "  [8] mimo-v2-tts" -ForegroundColor White
        Write-Host "  [0] Custom model name     (Type the model ID yourself)" -ForegroundColor White
        Write-Host ""
        $modelChoice = Read-Host "Select (0-8, default 1)"
        if ($modelChoice -eq "") { $modelChoice = "1" }

        $apiKey = Read-ApiKey "Enter your Xiaomi MiMo API Key"
        if ([string]::IsNullOrEmpty($apiKey)) { Write-Host "API Key cannot be empty!" -ForegroundColor Red; Wait-And-Exit }

        Write-Host ""
        Write-Host "Enter API Base URL (default: https://api.xiaomimimo.com/v1):" -ForegroundColor Cyan
        $baseUrl = Read-Host "Base URL"
        if ([string]::IsNullOrEmpty($baseUrl)) { $baseUrl = "https://api.xiaomimimo.com/v1" }

        $modelMap = @{
            "1" = "mimo-v2.5-pro"
            "2" = "mimo-v2.5"
            "3" = "mimo-v2.5-tts-voiceclone"
            "4" = "mimo-v2.5-tts-voicedesign"
            "5" = "mimo-v2.5-tts"
            "6" = "mimo-v2-pro"
            "7" = "mimo-v2-omni"
            "8" = "mimo-v2-tts"
        }

        if ($modelChoice -eq "0") {
            Write-Host ""
            Write-Host "Enter the exact model name/ID:" -ForegroundColor Cyan
            $modelId = Read-Host "Model name"
            while ([string]::IsNullOrEmpty($modelId)) {
                Write-Host "Model name cannot be empty!" -ForegroundColor Red
                $modelId = Read-Host "Model name"
            }
        } else {
            $modelId = $modelMap[$modelChoice]
        }
        $modelName = $modelId

        $providerConfig = Build-ProviderConfig -Name "mimo" `
            -BaseUrl $baseUrl `
            -Api "openai-completions" `
            -ApiKey $apiKey `
            -ModelId $modelId `
            -ModelName $modelName `
            -ContextWindow 128000 `
            -MaxTokens 8192

        $providerName = "mimo"
        $providerLabel = "Xiaomi MiMo"
    }

    "3" {
        # Volcengine
        Clear-Host
        Write-Title "Volcengine Configuration"
        Write-Host "  ByteDance Volcengine - Coding Plan" -ForegroundColor DarkGray
        Write-Host "  Console: https://console.volcengine.com/ark" -ForegroundColor DarkGray
        Write-Host "  Docs: https://www.volcengine.com/docs/82379/1928261" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  === CODING PLAN USERS ===" -ForegroundColor Yellow
        Write-Host "  If you subscribed to Coding Plan, use this setup." -ForegroundColor Yellow
        Write-Host "  The API uses a DIFFERENT base URL from standard API:" -ForegroundColor Yellow
        Write-Host "  https://ark.cn-beijing.volces.com/api/coding/v3" -ForegroundColor Yellow
        Write-Host "  =========================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Select Coding Plan model:" -ForegroundColor White
        Write-Host "  [1] doubao-seed-2.0-code     (Coding optimized, recommended)" -ForegroundColor White
        Write-Host "  [2] doubao-seed-2.0-pro      (Flagship model)" -ForegroundColor White
        Write-Host "  [3] doubao-seed-2.0-lite     (Lite, fast)" -ForegroundColor White
        Write-Host "  [4] doubao-seed-code          (Previous gen code)" -ForegroundColor White
        Write-Host "  [5] ark-code-latest           (Auto-select best model)" -ForegroundColor White
        Write-Host "  [0] Custom model name         (Type model name yourself)" -ForegroundColor White
        Write-Host ""
        $modelChoice = Read-Host "Select (0-5, default 1)"
        if ($modelChoice -eq "") { $modelChoice = "1" }

        $apiKey = Read-ApiKey "Enter your Volcengine API Key (from console.volcengine.com/ark/apikey)"
        if ([string]::IsNullOrEmpty($apiKey)) { Write-Host "API Key cannot be empty!" -ForegroundColor Red; Wait-And-Exit }

        Write-Host ""
        Write-Host "Enter API Base URL (default for Coding Plan: https://ark.cn-beijing.volces.com/api/coding/v3):" -ForegroundColor Cyan
        Write-Host "  NOTE: Do NOT use /api/v3 - it wont use your Coding Plan quota!" -ForegroundColor Yellow
        $baseUrl = Read-Host "Base URL"
        if ([string]::IsNullOrEmpty($baseUrl)) { $baseUrl = "https://ark.cn-beijing.volces.com/api/coding/v3" }

        $modelMap = @{
            "1" = @{ id = "doubao-seed-2.0-code"; name = "Doubao Seed 2.0 Code"; ctx = 256000; tokens = 128000 }
            "2" = @{ id = "doubao-seed-2.0-pro";  name = "Doubao Seed 2.0 Pro";  ctx = 256000; tokens = 128000 }
            "3" = @{ id = "doubao-seed-2.0-lite"; name = "Doubao Seed 2.0 Lite"; ctx = 256000; tokens = 128000 }
            "4" = @{ id = "doubao-seed-code";     name = "Doubao Seed Code";     ctx = 256000; tokens = 128000 }
            "5" = @{ id = "ark-code-latest";      name = "Ark Code Latest";      ctx = 256000; tokens = 128000 }
        }

        if ($modelChoice -eq "0") {
            Write-Host ""
            Write-Host "Enter the exact model name:" -ForegroundColor Cyan
            $modelId = Read-Host "Model name"
            while ([string]::IsNullOrEmpty($modelId)) {
                Write-Host "Model name cannot be empty!" -ForegroundColor Red
                $modelId = Read-Host "Model name"
            }
            $modelName = $modelId
            $contextWindow = 256000
            $maxTokens = 128000
        } else {
            $m = $modelMap[$modelChoice]
            $modelId = $m.id
            $modelName = $m.name
            $contextWindow = $m.ctx
            $maxTokens = $m.tokens
        }

        $providerConfig = Build-ProviderConfig -Name "volcano" `
            -BaseUrl $baseUrl `
            -Api "openai-completions" `
            -ApiKey $apiKey `
            -ModelId $modelId `
            -ModelName $modelName `
            -ContextWindow $contextWindow `
            -MaxTokens $maxTokens

        $providerName = "volcano"
        $providerLabel = "Volcengine (Coding Plan)"
    }

    "4" {
        # Custom OpenAI Compatible
        Clear-Host
        Write-Title "Custom OpenAI Compatible Configuration"
        Write-Host "  For any OpenAI API format compatible AI service" -ForegroundColor DarkGray
        Write-Host ""

        $apiKey = Read-ApiKey "Enter API Key"
        if ([string]::IsNullOrEmpty($apiKey)) { Write-Host "API Key cannot be empty!" -ForegroundColor Red; Wait-And-Exit }

        Write-Host ""
        Write-Host "Enter Base URL (e.g. https://api.openai.com/v1):" -ForegroundColor Cyan
        $baseUrl = Read-Host "Base URL"
        while ([string]::IsNullOrEmpty($baseUrl)) {
            Write-Host "Base URL is required!" -ForegroundColor Red
            $baseUrl = Read-Host "Base URL"
        }

        Write-Host ""
        Write-Host "Enter model ID (e.g. gpt-4o):" -ForegroundColor Cyan
        $modelId = Read-Host "Model ID"
        while ([string]::IsNullOrEmpty($modelId)) {
            Write-Host "Model ID is required!" -ForegroundColor Red
            $modelId = Read-Host "Model ID"
        }

        Write-Host ""
        Write-Host "Enter display name (default same as model ID):" -ForegroundColor Cyan
        $modelName = Read-Host "Display name"
        if ([string]::IsNullOrEmpty($modelName)) { $modelName = $modelId }

        Write-Host ""
        Write-Host "Context window size (default 128000):" -ForegroundColor Cyan
        $ctxStr = Read-Host "Context window"
        $ctx = if ([int]::TryParse($ctxStr, [ref]0)) { [int]$ctxStr } else { 128000 }

        Write-Host ""
        Write-Host "Max output tokens (default 8192):" -ForegroundColor Cyan
        $tokStr = Read-Host "Max tokens"
        $tokens = if ([int]::TryParse($tokStr, [ref]0)) { [int]$tokStr } else { 8192 }

        $providerConfig = Build-ProviderConfig -Name "custom" `
            -BaseUrl $baseUrl `
            -Api "openai-completions" `
            -ApiKey $apiKey `
            -ModelId $modelId `
            -ModelName $modelName `
            -ContextWindow $ctx `
            -MaxTokens $tokens

        $providerName = "custom"
        $providerLabel = "Custom"
    }

    "5" {
        # Local Model (Ollama / LM Studio / vLLM / text-gen-webui)
        Clear-Host
        Write-Title "Local Model Configuration"
        Write-Host "  Connect to a locally running AI model server" -ForegroundColor DarkGray
        Write-Host "  Supports: Ollama, LM Studio, vLLM, text-gen-webui, etc." -ForegroundColor DarkGray
        Write-Host ""

        # === Step 1: Server type ===
        Write-Host "Step 1: Select local server type:" -ForegroundColor Yellow
        Write-Host "  [1] Ollama              (http://localhost:11434/v1)" -ForegroundColor White
        Write-Host "  [2] LM Studio           (http://localhost:1234/v1)" -ForegroundColor White
        Write-Host "  [3] vLLM                (http://localhost:8000/v1)" -ForegroundColor White
        Write-Host "  [4] Other / Custom URL" -ForegroundColor White
        Write-Host ""
        $serverChoice = Read-Host "Select (1-4, default 1)"
        if ($serverChoice -eq "") { $serverChoice = "1" }

        $localUrls = @{
            "1" = "http://localhost:11434/v1"
            "2" = "http://localhost:1234/v1"
            "3" = "http://localhost:8000/v1"
        }

        if ($localUrls.ContainsKey($serverChoice)) {
            $baseUrl = $localUrls[$serverChoice]
            Write-Host ""
            Write-Host "  Using URL: $baseUrl" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "  Enter your server URL (e.g. http://192.168.1.100:11434/v1):" -ForegroundColor Cyan
            $baseUrl = Read-Host "Server URL"
            while ([string]::IsNullOrEmpty($baseUrl)) {
                Write-Host "URL cannot be empty!" -ForegroundColor Red
                $baseUrl = Read-Host "Server URL"
            }
        }

        # Clean up URL
        $baseUrl = $baseUrl -replace '/chat/completions$', ''
        $baseUrl = $baseUrl -replace '/$', ''

        # === Auto-detect installed models ===
        $detectedModels = @()
        $apiBase = $baseUrl -replace '/v1$', ''

        if ($serverChoice -eq "1") {
            # Ollama: GET /api/tags
            Write-Host ""
            Write-Host "  Detecting installed Ollama models..." -ForegroundColor Cyan
            try {
                $ollamaResp = Invoke-RestMethod -Uri "${apiBase}/api/tags" -Method Get -TimeoutSec 5 -ErrorAction Stop
                if ($ollamaResp.models -and $ollamaResp.models.Count -gt 0) {
                    $detectedModels = $ollamaResp.models | ForEach-Object { $_.name }
                    Write-Host "  Found $($detectedModels.Count) installed model(s)!" -ForegroundColor Green
                } else {
                    Write-Host "  No models installed yet." -ForegroundColor Yellow
                }
            } catch {
                Write-Host "  Could not connect to Ollama API, will show model suggestions instead." -ForegroundColor Yellow
            }
        } elseif ($serverChoice -eq "2" -or $serverChoice -eq "3") {
            # LM Studio / vLLM: GET /v1/models
            Write-Host ""
            Write-Host "  Detecting installed models..." -ForegroundColor Cyan
            try {
                $modelsResp = Invoke-RestMethod -Uri "${baseUrl}/models" -Method Get -TimeoutSec 5 -ErrorAction Stop
                if ($modelsResp.data -and $modelsResp.data.Count -gt 0) {
                    $detectedModels = $modelsResp.data | ForEach-Object { $_.id }
                    Write-Host "  Found $($detectedModels.Count) loaded model(s)!" -ForegroundColor Green
                } else {
                    Write-Host "  No models loaded. Please load a model in your app first." -ForegroundColor Yellow
                }
            } catch {
                Write-Host "  Could not connect, will show model suggestions instead." -ForegroundColor Yellow
            }
        }

        # === Step 2: Model family ===
        Write-Host ""
        Write-Host "Step 2: Select model family (for context/token presets):" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  [1] Qwen3 / Qwen2.5      (通义千问系列)" -ForegroundColor White
        Write-Host "  [2] DeepSeek-Coder / V2 / V3  (DeepSeek 系列)" -ForegroundColor White
        Write-Host "  [3] Code Llama / Llama 3  (Meta Llama 系列)" -ForegroundColor White
        Write-Host "  [4] Mixtral / Mistral     (Mistral AI 系列)" -ForegroundColor White
        Write-Host "  [5] GLM / ChatGLM         (智谱 ChatGLM 系列)" -ForegroundColor White
        Write-Host "  [6] Yi / Yi-Coder         (零一万物系列)" -ForegroundColor White
        Write-Host "  [7] Phi / Phi-3 / Phi-4   (Microsoft 系列)" -ForegroundColor White
        Write-Host "  [8] Gemma / Gemma-2       (Google 系列)" -ForegroundColor White
        Write-Host "  [9] QwQ / Qwen-reasoner  (推理模型)" -ForegroundColor White
        Write-Host "  [0] Generic / Other       (通用预设)" -ForegroundColor White
        Write-Host ""
        $modelFamily = Read-Host "Select (0-9, default 0)"
        if ($modelFamily -eq "") { $modelFamily = "0" }

        # Default presets by family
        $familyPresets = @{
            "1" = @{ ctx = 131072; tokens = 8192;  desc = "Qwen3/Qwen2.5" }
            "2" = @{ ctx = 131072; tokens = 8192;  desc = "DeepSeek" }
            "3" = @{ ctx = 131072; tokens = 8192;  desc = "Code Llama / Llama" }
            "4" = @{ ctx = 32768;  tokens = 8192;  desc = "Mixtral / Mistral" }
            "5" = @{ ctx = 131072; tokens = 8192;  desc = "GLM / ChatGLM" }
            "6" = @{ ctx = 131072; tokens = 4096;  desc = "Yi / Yi-Coder" }
            "7" = @{ ctx = 131072; tokens = 4096;  desc = "Phi" }
            "8" = @{ ctx = 8192;   tokens = 8192;  desc = "Gemma" }
            "9" = @{ ctx = 32768;  tokens = 8192;  desc = "QwQ / reasoning" }
            "0" = @{ ctx = 32768;  tokens = 4096;  desc = "Generic" }
        }

        $preset = $familyPresets[$modelFamily]
        if (-not $preset) { $preset = $familyPresets["0"] }

        # Model suggestions helper
        function Show-ModelSuggestions {
            param([string]$Family)
            Write-Host ""
            Write-Host "  Popular models you can install (Ollama):" -ForegroundColor DarkGray
            switch ($Family) {
                "1" {
                    Write-Host "    qwen3:32b    qwen3:14b    qwen3:8b     qwen3:0.5b" -ForegroundColor DarkGray
                    Write-Host "    qwen2.5:72b  qwen2.5:32b  qwen2.5:14b  qwen2.5:7b  qwen2.5-coder:32b" -ForegroundColor DarkGray
                    Write-Host "    qwen2.5-coder:14b  qwen2.5-coder:7b  qwen2.5-coder:1.5b" -ForegroundColor DarkGray
                }
                "2" {
                    Write-Host "    deepseek-coder-v2:16b  deepseek-coder-v2:lite" -ForegroundColor DarkGray
                    Write-Host "    deepseek-v3:671b (need quantized: deepseek-v3:236b)" -ForegroundColor DarkGray
                    Write-Host "    deepseek-r1:70b  deepseek-r1:32b  deepseek-r1:14b  deepseek-r1:8b" -ForegroundColor DarkGray
                    Write-Host "    deepseek-r1:7b  deepseek-r1:1.5b" -ForegroundColor DarkGray
                }
                "3" {
                    Write-Host "    llama3.3:70b  llama3.1:70b  llama3.1:8b  llama3.1:405b" -ForegroundColor DarkGray
                    Write-Host "    codellama:70b  codellama:34b  codellama:13b  codellama:7b" -ForegroundColor DarkGray
                }
                "4" {
                    Write-Host "    mixtral:8x22b  mixtral:8x7b  mistral:7b  mistral-nemo:12b" -ForegroundColor DarkGray
                    Write-Host "    mistral-small:24b  mistral-large:123b" -ForegroundColor DarkGray
                }
                "5" {
                    Write-Host "    glm4:9b  glm4:4b  glm3:6b  chatglm3:6b" -ForegroundColor DarkGray
                }
                "6" {
                    Write-Host "    yi:34b  yi:6b  yi-coder:9b  yi-coder:1.5b" -ForegroundColor DarkGray
                }
                "7" {
                    Write-Host "    phi4:14b  phi3:14b  phi3:3.8b  phi3:mini" -ForegroundColor DarkGray
                }
                "8" {
                    Write-Host "    gemma2:27b  gemma2:9b  gemma2:2b  gemma:7b  gemma:2b" -ForegroundColor DarkGray
                }
                "9" {
                    Write-Host "    qwq:32b  qwen2.5:32b (for reasoning tasks)" -ForegroundColor DarkGray
                }
                default {
                    Write-Host "    Check ollama.com/library for all available models" -ForegroundColor DarkGray
                }
            }
            Write-Host ""
        }
        Show-ModelSuggestions -Family $modelFamily

        # === Step 3: Model name ===
        Write-Host "Step 3: Select or enter model name:" -ForegroundColor Yellow

        if ($detectedModels.Count -gt 0) {
            Write-Host ""
            Write-Host "  Detected installed models:" -ForegroundColor Green
            $idx = 1
            $detectedMap = @{}
            foreach ($m in $detectedModels) {
                $detectedMap[$idx.ToString()] = $m
                Write-Host "  [$idx] $m" -ForegroundColor Green
                $idx++
            }
            Write-Host "  [0] Enter a different model name (from suggestions above)" -ForegroundColor White
            Write-Host ""
            $modelChoice = Read-Host "Select a detected model (1-$($detectedModels.Count)) or 0 to type manually"
            if ($modelChoice -eq "" -or $modelChoice -eq "0") {
                Write-Host ""
                Write-Host "  Enter model name (choose from suggestions above):" -ForegroundColor Cyan
                $modelId = Read-Host "Model name"
                while ([string]::IsNullOrEmpty($modelId)) {
                    Write-Host "Model name cannot be empty!" -ForegroundColor Red
                    $modelId = Read-Host "Model name"
                }
            } elseif ($detectedMap.ContainsKey($modelChoice)) {
                $modelId = $detectedMap[$modelChoice]
                Write-Host "  Selected: $modelId" -ForegroundColor Green
            } else {
                Write-Host "  Invalid choice, enter manually:" -ForegroundColor Yellow
                $modelId = Read-Host "Model name"
                while ([string]::IsNullOrEmpty($modelId)) {
                    Write-Host "Model name cannot be empty!" -ForegroundColor Red
                    $modelId = Read-Host "Model name"
                }
            }
        } else {
            Write-Host ""
            Write-Host "  Enter model name from suggestions above:" -ForegroundColor Cyan
            $modelId = Read-Host "Model name (e.g. qwen3:32b)"
            while ([string]::IsNullOrEmpty($modelId)) {
                Write-Host "Model name cannot be empty!" -ForegroundColor Red
                $modelId = Read-Host "Model name"
            }
        }
        $modelName = $modelId

        # === Step 4: API Key (optional) ===
        Write-Host ""
        Write-Host "Step 4: API Key (leave blank if not needed):" -ForegroundColor Yellow
        $apiKey = Read-Host "API Key (optional)"
        if ([string]::IsNullOrEmpty($apiKey)) { $apiKey = "not-needed" }

        # === Summary ===
        Clear-Host
        Write-Title "Local Model - Summary"
        Write-Host "  Server:   $baseUrl" -ForegroundColor White
        Write-Host "  Model:    $modelId" -ForegroundColor White
        Write-Host "  Family:   $($preset.desc)" -ForegroundColor DarkGray
        Write-Host "  Context:  $($preset.ctx) tokens" -ForegroundColor DarkGray
        Write-Host "  Max out:  $($preset.tokens) tokens" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "Want to adjust context window or max tokens?" -ForegroundColor Yellow
        $adjust = Read-Host "Adjust? (Y/N, default N)"
        if ($adjust -eq "Y" -or $adjust -eq "y") {
            Write-Host ""
            Write-Host "Context window size (current: $($preset.ctx)):" -ForegroundColor Cyan
            $ctxStr = Read-Host "Context window"
            $ctx = if ([int]::TryParse($ctxStr, [ref]0)) { [int]$ctxStr } else { $preset.ctx }

            Write-Host "Max output tokens (current: $($preset.tokens)):" -ForegroundColor Cyan
            $tokStr = Read-Host "Max tokens"
            $tokens = if ([int]::TryParse($tokStr, [ref]0)) { [int]$tokStr } else { $preset.tokens }
        } else {
            $ctx = $preset.ctx
            $tokens = $preset.tokens
        }

        $providerConfig = Build-ProviderConfig -Name "local" `
            -BaseUrl $baseUrl `
            -Api "openai-completions" `
            -ApiKey $apiKey `
            -ModelId $modelId `
            -ModelName $modelName `
            -ContextWindow $ctx `
            -MaxTokens $tokens

        $providerName = "local"
        $providerLabel = "Local ($modelId)"
    }

    default {
        Write-Host "Invalid option" -ForegroundColor Red
        Wait-And-Exit
    }
}

# ================================
#  Write Config File
# ================================
Clear-Host
Write-Title "Writing configuration..."

Test-ConfigFile

try {
    $existingConfig = Get-Content $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    $existingConfig = @{}
}

$config = @{}
if ($existingConfig.PSObject.Properties) {
    foreach ($prop in $existingConfig.PSObject.Properties) {
        $config[$prop.Name] = $prop.Value
    }
}

$config["models"] = @{
    mode = "merge"
    providers = @{
        $providerName = $providerConfig
    }
}

$config["agents"] = @{
    defaults = @{
        model = @{
            primary = "$providerName/$($providerConfig.models[0].id)"
        }
    }
}

if (-not $config.ContainsKey("gateway")) {
    $config["gateway"] = @{ auth = @{ mode = "none" } }
}

$json = $config | ConvertTo-Json -Depth 10
Set-Content -Path $ConfigPath -Value $json -Encoding UTF8

Write-Host "Config written: $ConfigPath" -ForegroundColor Green

Write-Host ""
Write-Host ("=" * 50) -ForegroundColor Cyan
Write-Host "  Done!" -ForegroundColor Green
Write-Host "  Provider: $providerLabel" -ForegroundColor White
Write-Host "  Model: $($providerConfig.models[0].id)" -ForegroundColor White
Write-Host ""
Write-Host "  Config: $ConfigPath" -ForegroundColor DarkGray
Write-Host ("=" * 50) -ForegroundColor Cyan

Write-Host ""
Write-Host "Start OpenClaw now?" -ForegroundColor Yellow
Write-Host "[Y] Yes  [N] No, I will start it manually" -ForegroundColor White
$startChoice = Read-Host "Select (Y/N, default Y)"
if ($startChoice -eq "" -or $startChoice -eq "Y" -or $startChoice -eq "y") {
    $launchers = @(
        "launch.bat",
        "Windows-Menu.bat",
        "start.bat",
        "run.bat"
    )
    $found = $null
    foreach ($l in $launchers) {
        $p = Join-Path $ScriptRoot $l
        if (Test-Path $p) { $found = $p; break }
    }
    if (-not $found) {
        # try wildcard
        $found = Get-ChildItem $ScriptRoot -Filter "*.bat" | Where-Object { $_.Name -like "*启动*" -or $_.Name -like "*start*" -or $_.Name -like "*launch*" -or $_.Name -like "*run*" } | Select-Object -First 1 -ExpandProperty FullName
    }
    if ($found) {
        Write-Host "Starting OpenClaw..." -ForegroundColor Green
        Start-Process -FilePath $found -WorkingDirectory $ScriptRoot
        Write-Host "Started!" -ForegroundColor Green
    } else {
        Write-Host "No launcher script found. Run manually:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  cd /d $ScriptRoot" -ForegroundColor White
        Write-Host "  ""$NodeExe"" ""$ClawEntry""" -ForegroundColor White
    }
}

Wait-And-Exit










# 在 WSL 中从零开始配置 Hermes 使用 GitHub Copilot Provider 教程

本文适用于 **WSL 里的 Ubuntu** 环境，目标是从零开始完成以下事情：

1. 安装 `gh`（GitHub CLI）
2. 登录 GitHub
3. 检查 GitHub Copilot CLI 是否可用
4. 安装 Hermes
5. 把 Hermes 的默认 provider 切换为 **GitHub Copilot**
6. 验证 Hermes 能正常工作
7. 打开 Hermes Dashboard

---

## 0. 环境说明

本文默认你在 **WSL Ubuntu** 中操作。

先确认系统版本：

```bash
cat /etc/os-release
```

如果你是 Ubuntu / Debian 系列，下面的 `apt` 安装方式可以直接使用。

---

## 1. 安装 GitHub CLI (`gh`)

GitHub CLI 官方推荐的 Debian / Ubuntu 安装方式如下。

### 1.1 添加官方源并安装

```bash
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
  && sudo mkdir -p -m 755 /etc/apt/keyrings \
  && out=$(mktemp) && wget -nv -O "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  && cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh -y
```

### 1.2 验证安装

```bash
gh --version
```

看到版本号就说明安装成功。

---

## 2. 登录 GitHub

### 2.1 用浏览器登录

最简单的是：

```bash
gh auth login
```

推荐选择：

- **GitHub.com**
- **HTTPS**
- **Login with a web browser**

如果你在 WSL 中不方便自动开浏览器，也可以手动复制验证码完成登录。

### 2.2 检查登录状态

```bash
gh auth status
```

你应该能看到类似：

- 已登录的 GitHub 用户名
- token 存储状态
- token scopes（例如 `repo`, `read:org`, `gist`, `workflow`）

---

## 3. 确认 GitHub Copilot CLI 可用

先确认 `gh copilot` 本身工作正常。

### 3.1 查看帮助

```bash
gh copilot --help
```

### 3.2 做一个最小测试

```bash
gh copilot -p "Reply with exactly GH_COPILOT_OK" --allow-all-tools --output-format text
```

如果返回：

```text
GH_COPILOT_OK
```

说明 **GitHub Copilot CLI** 本身可用。

> 注意：`gh copilot` 可用，不代表 Hermes 已经自动切到 Copilot。下面还需要配置 Hermes。

---

## 4. 安装 Hermes

如果你还没安装 Hermes，可以用官方安装脚本：

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

安装完成后，重新打开 shell，或者执行：

```bash
source ~/.bashrc
```

然后检查：

```bash
hermes --version
```

如果你是源码方式安装，也可以用：

```bash
python -m hermes_cli.main --version
```

---

## 5. 找到 Hermes 配置文件位置

Hermes 的主配置文件通常在：

```bash
hermes config path
```

通常会输出：

```bash
~/.hermes/config.yaml
```

Hermes 的 `.env` 文件位置通常在：

```bash
hermes config env-path
```

通常会输出：

```bash
~/.hermes/.env
```

---

## 6. 把 Hermes 默认 provider 改成 GitHub Copilot

Hermes 使用 GitHub Copilot 时，核心配置如下：

```yaml
model:
  default: gpt-5.4
  api_mode: codex_responses
  provider: "copilot"
  api_key: ""
  base_url: "https://api.githubcopilot.com"
```

### 6.1 直接编辑配置文件

打开配置文件：

```bash
nano ~/.hermes/config.yaml
```

把 `model:` 这一段改成：

```yaml
model:
  default: gpt-5.4
  api_mode: codex_responses
  provider: "copilot"

  # API configuration — GitHub Copilot
  api_key: ""
  base_url: "https://api.githubcopilot.com"
```

保存退出。

说明：

- `provider` 要设置为 `copilot`
- `api_mode` 要设置为 `codex_responses`
- `base_url` 要设置为 `https://api.githubcopilot.com`
- `api_key` 可以留空

---

## 7. 验证 Hermes 的 Copilot provider 是否可用

推荐先做一个最小验证：

```bash
env -u COPILOT_GITHUB_TOKEN -u GH_TOKEN -u GITHUB_TOKEN \
python -m hermes_cli.main chat -q "Reply with exactly: COPILOT_OK" \
  --provider copilot --model gpt-5.4
```

如果成功，应该返回类似：

```text
COPILOT_OK
```

这说明 Hermes 已经可以正常使用 GitHub Copilot provider。

### 7.1 再验证默认配置是否生效

当你已经把 `config.yaml` 改成默认 `provider: copilot` 后，再跑：

```bash
env -u COPILOT_GITHUB_TOKEN -u GH_TOKEN -u GITHUB_TOKEN \
python -m hermes_cli.main chat -q "Reply with exactly: DEFAULT_COPILOT_OK" \
  --model gpt-5.4
```

如果返回结果正确，就说明后续直接运行 `hermes` 时，会默认走 GitHub Copilot。

> 补充：如果你本机手动设置过 `COPILOT_GITHUB_TOKEN`、`GH_TOKEN` 或 `GITHUB_TOKEN`，它们可能会覆盖 `gh auth login` 的登录结果。大多数从零开始的环境不需要额外配置这些变量。

---

## 8. 日常使用方式

### 8.1 直接启动 Hermes

```bash
hermes
```

### 8.2 单次提问

```bash
hermes chat -q "用中文解释一下这个项目是做什么的"
```

### 8.3 强制指定 provider（调试时很好用）

```bash
hermes chat -q "Reply with exactly TEST_OK" --provider copilot --model gpt-5.4
```

---

## 9. 打开 Hermes Dashboard

Hermes 的正确 Dashboard 启动方式是：

```bash
hermes dashboard
```

默认会监听：

```text
http://127.0.0.1:9119/
```

如果你不想自动开浏览器：

```bash
hermes dashboard --no-open
```

### 9.1 正确打开地址

在浏览器里打开：

```text
http://127.0.0.1:9119/
```

### 9.2 不要打开 5173

如果你看到 `http://127.0.0.1:5173/`，那通常只是前端开发服务器，不是正式的 Hermes Dashboard。

**结论：**
- `9119`：正式 Hermes Dashboard
- `5173`：前端开发服务器，不是正常入口

---

## 10. 建议做一次自检

```bash
hermes doctor
```

如果你想让 Hermes 尝试自动修一些常见问题：

```bash
hermes doctor --fix
```

---

## 11. 常见问题

### 11.1 `gh auth status` 没登录

重新登录：

```bash
gh auth login
```

然后再检查：

```bash
gh auth status
```

### 11.2 `gh copilot` 不可用

先确认：

```bash
gh copilot --help
```

如果仍然不行，通常需要检查：

- GitHub CLI 是否安装正确
- GitHub 账号是否登录
- Copilot 权限或订阅状态是否正常

### 11.3 Hermes 改了配置但还没生效

改完 `~/.hermes/config.yaml` 后：

- 退出当前 Hermes 会话
- 重新启动 `hermes`

必要时重新开一个 shell。

### 11.4 Dashboard 打开是空白页

先确认你打开的是不是：

```text
http://127.0.0.1:9119/
```

如果你开的是 `5173`，那大概率是前端开发服务器，不是正式 Dashboard。

---

## 12. 推荐的最终状态

当你配置完成后，建议达到以下状态：

### 12.1 `gh auth status` 正常

```bash
gh auth status
```

### 12.2 `gh copilot` 正常

```bash
gh copilot -p "Reply with exactly GH_COPILOT_OK" --allow-all-tools --output-format text
```

### 12.3 Hermes 的 Copilot provider 正常

```bash
env -u COPILOT_GITHUB_TOKEN -u GH_TOKEN -u GITHUB_TOKEN \
python -m hermes_cli.main chat -q "Reply with exactly COPILOT_OK" \
  --provider copilot --model gpt-5.4
```

### 12.4 默认配置已切换

`~/.hermes/config.yaml` 中应类似：

```yaml
model:
  default: gpt-5.4
  api_mode: codex_responses
  provider: "copilot"
  api_key: ""
  base_url: "https://api.githubcopilot.com"
```

### 12.5 Dashboard 正确打开

```text
http://127.0.0.1:9119/
```

---

## 13. 一套可直接复制的最小流程

如果你想快速做一遍，下面是简版：

### 安装 `gh`

```bash
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
  && sudo mkdir -p -m 755 /etc/apt/keyrings \
  && out=$(mktemp) && wget -nv -O "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  && cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh -y
```

### 登录 GitHub

```bash
gh auth login
gh auth status
```

### 检查 Copilot CLI

```bash
gh copilot -p "Reply with exactly GH_COPILOT_OK" --allow-all-tools --output-format text
```

### 安装 Hermes

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
hermes --version
```

### 编辑配置

```bash
nano ~/.hermes/config.yaml
```

写成：

```yaml
model:
  default: gpt-5.4
  api_mode: codex_responses
  provider: "copilot"
  api_key: ""
  base_url: "https://api.githubcopilot.com"
```

### 验证 Hermes Copilot provider

```bash
env -u COPILOT_GITHUB_TOKEN -u GH_TOKEN -u GITHUB_TOKEN \
python -m hermes_cli.main chat -q "Reply with exactly: COPILOT_OK" \
  --provider copilot --model gpt-5.4
```

### 启动 Dashboard

```bash
hermes dashboard --no-open
```

浏览器打开：

```text
http://127.0.0.1:9119/
```

---

## 14. 结语

如果一切正常，你现在已经完成了：

- 在 **WSL Ubuntu** 中安装 `gh`
- 登录 GitHub
- 验证 `gh copilot`
- 配置 Hermes 默认走 **GitHub Copilot provider**
- 验证 Hermes 实际能调用 Copilot
- 打开正确的 Hermes Dashboard

如果你后面还想继续完善，我建议下一步做这些之一：

1. 把 `hermes dashboard` 做成后台常驻
2. 写一个一键初始化脚本
3. 给这个 WSL 环境做一个“新机器迁移清单”

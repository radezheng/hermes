# Hermes + GitHub Copilot on WSL

一个从零开始的最小可用说明：在 **WSL Ubuntu** 里安装 `gh`、登录 GitHub、安装 Hermes，并把 Hermes 默认 provider 切到 **GitHub Copilot**。

---

## 1. 安装 gh

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

验证：

```bash
gh --version
```

---

## 2. 登录 GitHub

```bash
gh auth login
gh auth status
```

推荐：
- GitHub.com
- HTTPS
- Login with a web browser

---

## 3. 检查 gh copilot

```bash
gh copilot --help
```

最小验证：

```bash
gh copilot -p "Reply with exactly GH_COPILOT_OK" --allow-all-tools --output-format text
```

---

## 4. 安装 Hermes

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
source ~/.bashrc
hermes --version
```

---

## 5. 配置 Hermes 默认走 Copilot

编辑：

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

---

## 6. 验证 Hermes Copilot provider

```bash
env -u COPILOT_GITHUB_TOKEN -u GH_TOKEN -u GITHUB_TOKEN \
python -m hermes_cli.main chat -q "Reply with exactly: COPILOT_OK" \
  --provider copilot --model gpt-5.4
```

如果返回 `COPILOT_OK`，说明 Hermes 已能正常使用 GitHub Copilot provider。

> 备注：如果你之前手动设置过 `COPILOT_GITHUB_TOKEN`、`GH_TOKEN` 或 `GITHUB_TOKEN`，它们可能影响登录结果。全新环境通常不用额外设置这些变量。

---

## 7. 打开 Dashboard

```bash
hermes dashboard --no-open
```

浏览器访问：

```text
http://127.0.0.1:9119/
```

> 不要把 `5173` 当正式入口。那通常只是前端 dev server。

---

## 8. 常见问题

### `gh copilot` 不可用
先确认 GitHub CLI 已安装、已登录，并且 Copilot 权限正常。

### Hermes 改了配置但没生效
退出当前 Hermes 会话，重新打开 shell，再启动 `hermes`。

### Dashboard 是空白页
请确认打开的是：

```text
http://127.0.0.1:9119/
```

不是 `5173`。

---

## 文件说明

本目录还附带：
- `hermes-gh-copilot-wsl-setup.md`：完整版教程
- `setup-hermes-gh-copilot.sh`：一键初始化脚本
- `blog-version.md`：适合发博客/分享的版本

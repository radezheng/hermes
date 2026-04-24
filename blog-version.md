# 在 WSL 里把 Hermes 配成 GitHub Copilot：一份适合从零开始的配置指南

如果你平时在 WSL 里工作，又想把 Hermes Agent 的默认模型入口切到 **GitHub Copilot provider**，其实整套流程并不复杂。

如果你是第一次安装 Hermes，安装过程中其实就可以直接把 **GitHub Copilot** 选成默认 provider；如果当时没选，或者想在正式切换前先把环境准备好，也可以按这篇文章里的顺序先把 `gh`、`gh copilot` 和相关验证命令都准备好，再回头调整 Hermes 配置。

从零开始，大致只需要完成这几步：

1. 安装 GitHub CLI（`gh`）
2. 登录 GitHub
3. 确认 `gh copilot` 可用
4. 安装 Hermes
5. 修改 Hermes 配置，让默认 provider 变成 Copilot
6. 做一次最小验证
7. 用正确地址打开 Dashboard

整篇文章就是按这个顺序来。

---

## 先看最后想达到的状态

当一切配置完成后，你的环境大致会是这样：

- `gh` 已经安装
- `gh auth login` 已登录成功
- `gh copilot` 能正常响应
- Hermes 默认 provider 是 `copilot`
- Hermes Dashboard 用 `http://127.0.0.1:9119/` 打开

Hermes 里的核心配置大概如下：

```yaml
model:
  default: gpt-5.4
  api_mode: codex_responses
  provider: "copilot"
  api_key: ""
  base_url: "https://api.githubcopilot.com"
```

---

## 第一步：在 WSL 安装 gh

如果你是 Ubuntu on WSL，可以直接使用 GitHub CLI 官方推荐的安装方式：

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

安装完成后，先确认版本：

```bash
gh --version
```

如果这里有输出，说明 `gh` 已经装好了。

---

## 第二步：登录 GitHub

接着执行：

```bash
gh auth login
```

推荐选择：

- GitHub.com
- HTTPS
- 浏览器登录

完成之后再检查一下：

```bash
gh auth status
```

只要这里显示你已经登录，就可以继续往下走。

---

## 第三步：确认 gh copilot 可用

在切 Hermes 之前，先确保 GitHub Copilot CLI 本身正常。

先看帮助：

```bash
gh copilot --help
```

再做一个很小的测试：

```bash
gh copilot -p "Reply with exactly GH_COPILOT_OK" --allow-all-tools --output-format text
```

如果返回 `GH_COPILOT_OK`，说明 GitHub Copilot CLI 已经准备好了。

这里的意思不是“这一步做完 Hermes 就自动可用了”，而是先确认 GitHub 这一侧没有问题。

---

## 第四步：安装 Hermes

如果你还没安装 Hermes，可以直接执行：

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

安装结束后，重新加载 shell：

```bash
source ~/.bashrc
```

再确认版本：

```bash
hermes --version
```

只要这里有版本输出，就说明 Hermes 已经装好。

---

## 第五步：把 Hermes 默认 provider 改成 Copilot

Hermes 的配置文件通常在：

```bash
~/.hermes/config.yaml
```

打开它：

```bash
nano ~/.hermes/config.yaml
```

然后把 `model` 段改成这样：

```yaml
model:
  default: gpt-5.4
  api_mode: codex_responses
  provider: "copilot"

  # API configuration — GitHub Copilot
  api_key: ""
  base_url: "https://api.githubcopilot.com"
```

这里有几个关键点：

- `provider` 是 `copilot`
- `api_mode` 是 `codex_responses`
- `base_url` 指向 GitHub Copilot API
- `api_key` 可以留空

因为这里主要复用的是 GitHub 登录状态，而不是手填一个普通 API key。

---

## 第六步：验证 Hermes 是否真的能调用 Copilot

改完配置之后，建议立刻做一次最小验证。

```bash
env -u COPILOT_GITHUB_TOKEN -u GH_TOKEN -u GITHUB_TOKEN \
hermes chat -q "Reply with exactly: COPILOT_OK" \
  --provider copilot --model gpt-5.4
```

如果这里成功返回：

```text
COPILOT_OK
```

说明 Hermes 的 Copilot provider 已经打通了。

这一步非常重要，因为它比“只看配置文件”更可靠。

> 补充一句：全新环境通常不需要手动设置 GitHub token 环境变量；如果你以前额外配置过它们，才需要顺手检查是否冲突。

---

## 第七步：打开 Hermes Dashboard

Hermes Dashboard 的正确启动方式是：

```bash
hermes dashboard
```

默认地址是：

```text
http://127.0.0.1:9119/
```

如果你不想自动打开浏览器，可以改成：

```bash
hermes dashboard --no-open
```

然后在浏览器里手动访问：

```text
http://127.0.0.1:9119/
```

这里有个很值得提前记住的小点：

- `9119` 是正式 Dashboard
- `5173` 如果出现，通常只是前端开发服务器，不是正常入口

所以如果你看到空白页，优先确认自己打开的是不是 `9119`。

---

## 到这里，你就已经完成了什么？

如果前面的步骤都顺利，你现在已经完成了：

- 在 WSL 安装 `gh`
- 登录 GitHub
- 验证 `gh copilot`
- 安装 Hermes
- 把 Hermes 默认 provider 切到 GitHub Copilot
- 完成一次 Hermes 最小验证
- 正确打开 Hermes Dashboard

这套配置完成以后，后面无论你是在终端里直接跑 Hermes，还是通过 Dashboard 管理，都顺手很多。

---

## 最后给一个最小流程版

如果你只想快速照着做，可以直接按这个顺序：

```bash
# 安装 gh
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
  && sudo mkdir -p -m 755 /etc/apt/keyrings \
  && out=$(mktemp) && wget -nv -O "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  && cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh -y

# 登录 GitHub
gh auth login
gh auth status

# 检查 gh copilot
gh copilot -p "Reply with exactly GH_COPILOT_OK" --allow-all-tools --output-format text

# 安装 Hermes
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
source ~/.bashrc
hermes --version

# 编辑 Hermes 配置
nano ~/.hermes/config.yaml

# 验证 Hermes Copilot provider
env -u COPILOT_GITHUB_TOKEN -u GH_TOKEN -u GITHUB_TOKEN \
hermes chat -q "Reply with exactly: COPILOT_OK" \
  --provider copilot --model gpt-5.4

# 打开 Dashboard
hermes dashboard --no-open
```

浏览器访问：

```text
http://127.0.0.1:9119/
```

---

## 结语

如果你想在本地 WSL 环境里把 Hermes 和 GitHub Copilot 结合起来用，这套方式是一条比较直接、也比较容易复现的路径。

它的好处是：

- GitHub 账号体系本来就在用
- `gh` 和 `gh copilot` 这套链路本身已经比较顺手
- Hermes 再往上补齐更完整的 agent 能力、工具调用和 Dashboard

所以一旦配好，终端和 Dashboard 的使用体验会比较统一。

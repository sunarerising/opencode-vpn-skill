# OpenCode VPN Web Search Skill

让 [OpenCode](https://opencode.ai) 通过本地 VPN 代理进行网络搜索和网页抓取。

## 解决的问题

OpenCode 内置的 `webfetch` / `websearch` 工具运行在后台服务器，在中国大陆等地区可能无法访问 GitHub、Google 等网站。本 Skill 通过引导 Agent 使用本地的 `bash` + `curl` 命令，借助你本机的 VPN 代理通道完成网络请求。

## 前置条件

- 已安装 [OpenCode](https://opencode.ai/download)（CLI / Desktop / TUI 均可）
- 已安装并运行本地代理客户端（如 [Clash Verge](https://github.com/clash-verge-rev/clash-verge-rev)、[FIClash](https://ficlash.com/)、[Mihomo](https://github.com/MetaCubeX/mihomo) 等）
- `curl` 命令可用（Windows 10+ 自带 `curl.exe`，macOS/Linux 自带 `curl`）

## 快速安装

### Windows (PowerShell)

```powershell
# 克隆仓库
git clone https://github.com/sunarerising/opencode-vpn-skill.git
cd opencode-vpn-skill

# 运行安装脚本
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

### macOS / Linux

```bash
git clone https://github.com/sunarerising/opencode-vpn-skill.git
cd opencode-vpn-skill

./install.sh
```

安装完成后**重启 OpenCode** 即可生效。

## 安装脚本做了什么

| 步骤 | 说明 |
|------|------|
| 1. 检测 OpenCode | 确认已安装 OpenCode |
| 2. 设置代理端口 | 交互式询问代理地址（默认 `http://127.0.0.1:7890`） |
| 3. 配置环境变量 | 将 `OPENCODE_VPN_PROXY` 写入用户级环境变量 |
| 4. 安装 Skill | 将 `SKILL.md` 复制到 `~/.config/opencode/skills/vpn-web-search/` |
| 5. 更新权限 | 在项目的 `opencode.json` 中添加 `webfetch: deny`（智能合并，不覆盖已有配置） |

## 手动安装

如果脚本不适用，可手动执行：

### 1. 设置环境变量

**Windows：**
```
[System.Environment]::SetEnvironmentVariable("OPENCODE_VPN_PROXY", "http://127.0.0.1:7890", "User")
```

**macOS / Linux：**
```bash
echo 'export OPENCODE_VPN_PROXY="http://127.0.0.1:7890"' >> ~/.bashrc
# 或 ~/.zshrc
```

将 `7890` 替换为你的代理端口。

### 2. 复制 Skill 文件

```
# Windows
Copy-Item -Recurse skills\vpn-web-search "$env:USERPROFILE\.config\opencode\skills\"

# macOS / Linux
cp -r skills/vpn-web-search ~/.config/opencode/skills/
```

### 3. 禁用 webfetch（可选但推荐）

在项目的 `opencode.json` 中添加：

```json
{
  "permission": {
    "webfetch": "deny"
  }
}
```

### 4. 重启 OpenCode

## 验证安装

1. 重启 OpenCode
2. 输入 `/skills` 或查看 available_skills，应包含 `vpn-web-search`
3. 要求 Agent 访问一个被屏蔽的网站，例如：
   > 访问 https://raw.githubusercontent.com/anomalyco/opencode/dev/AGENTS.md 并返回内容

Agent 应使用 `curl.exe --proxy http://127.0.0.1:7890` 而非 `webfetch` 工具。

## 自定义代理端口

如果你的代理端口不是 `7890`，修改环境变量即可：

```powershell
# Windows PowerShell
$env:OPENCODE_VPN_PROXY = "http://127.0.0.1:10809"
```

```bash
# macOS / Linux
export OPENCODE_VPN_PROXY="http://127.0.0.1:10809"
```

常见代理端口：

| 客户端 | 默认 HTTP 端口 |
|--------|---------------|
| Clash Verge | 7890 |
| FIClash | 7890 |
| Mihomo | 7890 |
| V2Ray | 10809 |
| SSR | 1080 |

## 常见问题

### Q: 重启 OpenCode 后 Skill 未出现？

- 确认 Skill 文件已放在正确的路径：`~/.config/opencode/skills/vpn-web-search/SKILL.md`
- 确认文件名是 `SKILL.md`（全大写）
- 确认 YAML frontmatter 包含 `name` 和 `description`

### Q: curl 命令报错 "Could not resolve proxy"？

- 确认代理客户端正在运行
- 确认环境变量端口号与代理客户端一致
- 检查防火墙是否阻止了本地回环连接

### Q: Windows 上 `curl` 被识别为 `Invoke-WebRequest`？

在 PowerShell 中使用 `curl.exe` 而非 `curl`。Skill 已默认使用 `curl.exe`。

### Q: 可否同时保留 webfetch 工具？

可以。删除 `opencode.json` 中的 `webfetch: deny` 即可。但 Agent 可能在两种方式间切换，不够稳定。

### Q: 访问国内网站（百度、知乎等）也会走代理？

会。当前 Skill 配置的是全量代理模式，`curl.exe --proxy` 不区分国内外 URL，所有请求都通过 VPN。

**后果：** 国内网站流量也会绕经代理服务器，速度可能略慢。

**推荐解决方案：** 在 FIClash/Clash 客户端中配置分流规则，国内 IP 直连、国外 IP 走代理。Clash 本身就是为这个设计的，修改分流规则对 OpenCode 完全透明，无需改动 Skill。

**备选方案：**
- 不推荐在 Skill/LLM 层面做 URL 判断（不可靠）
- 如果不需要代理访问内网，删除 `opencode.json` 中的 `webfetch: deny` 恢复默认即可

## 许可

MIT License

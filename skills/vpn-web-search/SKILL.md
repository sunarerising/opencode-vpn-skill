---
name: vpn-web-search
description: Use bash+curl through a local VPN proxy to fetch web pages and search the internet. Use this skill whenever you need to access URLs, fetch web content, or search online. NEVER use the webfetch or websearch tools for web access.
---

## Overview

This skill instructs the agent to use `bash` + `curl` through a local VPN proxy instead of OpenCode's built-in server-side `webfetch` tool. This is useful when:

- The target website is blocked from OpenCode's backend
- You need to access resources behind a firewall or geo-restriction
- You want all web traffic to go through your local network/VPN

## Proxy Configuration

All commands use the environment variable `OPENCODE_VPN_PROXY`. Make sure it is set before starting OpenCode:

**Windows (PowerShell):**
```
$env:OPENCODE_VPN_PROXY = "http://127.0.0.1:7890"
```

**macOS / Linux:**
```
export OPENCODE_VPN_PROXY="http://127.0.0.1:7890"
```

## Fetch a URL

Use the `bash` tool:

```
curl.exe --proxy $env:OPENCODE_VPN_PROXY -sL "<URL>"
```

- `-s` silent mode (no progress bar)
- `-L` follow redirects
- On **Windows PowerShell**, use `curl.exe` to avoid alias conflict with `Invoke-WebRequest`
- On **macOS / Linux**, use `curl` directly

## Fetch GitHub Raw Content

```
curl.exe --proxy $env:OPENCODE_VPN_PROXY -sL -H "Accept: application/vnd.github.v3.raw" "<URL>"
```

## Fetch GitHub API

```
curl.exe --proxy $env:OPENCODE_VPN_PROXY -sL -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "<URL>"
```

## Handle Long Output

Limit output to first 200 lines:

```
curl.exe --proxy $env:OPENCODE_VPN_PROXY -sL "<URL>" | Select-Object -First 200
```

## Save to Project Local Directory

For large pages, save to `.web/` using fixed filenames (each new fetch overwrites the previous):

```
curl.exe --proxy $env:OPENCODE_VPN_PROXY -sL "<URL>" -o ".web\fetch.html"
curl.exe --proxy $env:OPENCODE_VPN_PROXY -sL -H "Accept: text/markdown" "<URL>" -o ".web\fetch.md"
curl.exe --proxy $env:OPENCODE_VPN_PROXY -sL -H "Accept: application/json" "<URL>" -o ".web\fetch.json"
```

After saving, read the file with the `read` tool:

```
read(".web/fetch.md")
```

The `.web/` directory is gitignored. Fixed filenames prevent unlimited growth.

## Fallback: PowerShell Invoke-WebRequest

If `curl.exe` is unavailable on Windows:

```
Invoke-WebRequest -Uri "<URL>" -Proxy $env:OPENCODE_VPN_PROXY -UseBasicParsing | Select-Object -ExpandProperty Content
```

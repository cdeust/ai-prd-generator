# GitHub Device Flow Integration Guide

## Overview

The skill can fetch and analyze codebases directly from GitHub repositories using **Device Flow authentication** (the same method used by GitHub CLI). This allows you to access private repositories without needing to create an OAuth app.

## Key Benefits

✅ **No OAuth app needed** - Uses GitHub's public device flow endpoint
✅ **User-friendly** - Just enter a code at github.com/login/device
✅ **No secrets to manage** - No client_secret required
✅ **Individual tokens** - Each user gets their own token with separate rate limits
✅ **Works with private repos** - Full access to your private repositories

---

## How It Works

### Device Flow (Like GitHub CLI)

```
1. Skill requests device code from GitHub
   ↓
2. User visits github.com/login/device
   ↓
3. User enters the displayed code
   ↓
4. User authorizes the app
   ↓
5. Skill receives access token
   ↓
6. Token stored in macOS Keychain (encrypted)
   ↓
7. Fetch repositories automatically on future requests
```

No OAuth app creation required - GitHub handles everything!

---

## Usage

### First-Time Authentication

When you provide a GitHub repository URL for the first time:

```
User: "Generate a PRD for adding notifications.
       Codebase: https://github.com/mycompany/myapp"

Skill:
🔐 GitHub Authentication Required

📝 Please visit: https://github.com/login/device

🔑 Enter code: XXXX-XXXX

⏱️  Code expires in 15 minutes

🌐 Browser opened - paste code there
⏳ Waiting for authorization...
```

**In the browser:**
1. The browser opens automatically to https://github.com/login/device
2. Paste the code shown in terminal (XXXX-XXXX)
3. Click **"Continue"**
4. Review permissions (read repository, read organization)
5. Click **"Authorize"**

**Back in terminal:**
```
✅ Authenticated as @username
✅ Access token stored securely in macOS Keychain
📦 Fetching mycompany/myapp...
✅ Downloaded 347 files (respecting .gitignore)
📊 Indexing with RAG...
```

### Subsequent Uses

Once authenticated, the skill reuses the stored token:

```
User: "Analyze https://github.com/mycompany/another-repo"

Skill:
✅ GitHub already authenticated (@username)
📦 Fetching mycompany/another-repo...
✅ Downloaded 521 files
📊 Indexing with RAG...
```

---

## Configuration

The skill comes pre-configured with device flow enabled. Check `skill-config.json`:

```json
{
  "integrations": {
    "github": {
      "enabled": true,
      "auth_method": "device_flow",
      "scopes": ["repo", "read:org"]
    }
  }
}
```

**No additional setup required!**

---

## Features

### Private Repository Access

```
User: "Analyze https://github.com/mycompany/secret-api"

Skill:
✅ GitHub authenticated with 'repo' scope
✅ Access granted to private repository
📦 Fetching mycompany/secret-api...
✅ Downloaded 1,247 files from private repo
```

### Organization Repositories

```
User: "Analyze https://github.com/myorg/shared-library"

Skill:
✅ GitHub authenticated with 'read:org' scope
✅ Access to organization: myorg
📦 Fetching myorg/shared-library...
```

### Multiple Repositories

```
User: "Compare PRD requirements with these codebases:
- https://github.com/mycompany/api-backend
- https://github.com/mycompany/web-frontend
- https://github.com/mycompany/mobile-app"

Skill:
✅ GitHub authenticated
📦 Fetching 3 repositories...
✅ api-backend: 892 files
✅ web-frontend: 456 files
✅ mobile-app: 623 files
📊 Indexing 1,971 files total with RAG...
✅ Hybrid search ready across all 3 codebases
```

---

## Token Management

### Where Tokens Are Stored

- **macOS Keychain** - Encrypted storage
- **Service:** `ai-prd-generator`
- **Account:** `github`

### View Stored Token

```bash
# macOS Keychain Access app
# Search for: "ai-prd-generator"
# Shows: GitHub access token (encrypted)
```

### Revoke Access

**Option 1: Via GitHub (Recommended)**
1. Go to **GitHub Settings** → **Applications** → **Authorized OAuth Apps**
2. Find **"AI PRD Generator"**
3. Click **"Revoke"**

**Option 2: Delete from Keychain**
1. Open **Keychain Access** app
2. Search for **"ai-prd-generator"**
3. Delete the **"github"** entry

**Option 3: Via Command**
```bash
# Delete token from Keychain
security delete-generic-password -s "ai-prd-generator" -a "github"
```

### Token Lifetime

GitHub device flow tokens don't expire by default. To re-authenticate:
1. Revoke access (see above)
2. Next time you use a GitHub URL, you'll be prompted to authorize again

---

## Troubleshooting

### "Device code expired"

**Problem:** You didn't authorize within 15 minutes.

**Solution:**
- Run the PRD request again
- A new device code will be generated
- You'll have another 15 minutes to authorize

### "Access denied"

**Problem:** You clicked "Deny" during authorization.

**Solution:**
- Run the PRD request again
- Click "Authorize" this time

### "Rate limit exceeded"

**Problem:** GitHub API rate limit hit (5,000 requests/hour for authenticated users).

**Solution:**
- Wait for rate limit reset (shown in error message)
- Reduce number of repositories being fetched simultaneously

### "Repository not found or access denied"

**Possible causes:**
- Repository doesn't exist
- Repository is private and you don't have access
- OAuth token was revoked

**Solution:**
1. Verify repository URL is correct
2. Check you have access to the repository on GitHub
3. Re-authenticate if token was revoked

### Browser doesn't open automatically

**Problem:** `open` command failed or browser blocked.

**Solution:**
- Manually visit the URL shown in terminal: https://github.com/login/device
- Enter the code displayed
- Continue with authorization

---

## Security & Privacy

### What the Skill Can Access

With `repo` scope:
- ✅ Read all public and private repositories you have access to
- ✅ Read commit status
- ✅ Read repository metadata
- ❌ Cannot write, delete, or modify repositories
- ❌ Cannot access your password or other tokens

With `read:org` scope:
- ✅ Read organization membership
- ✅ Read organization repositories list
- ❌ Cannot modify organization settings

### Data Privacy

- ✅ **All code stays local** - Downloaded to your machine only
- ✅ **Token in Keychain** - Encrypted by macOS
- ✅ **No data uploaded** - Code never sent to external servers (except AI provider for embeddings)
- ✅ **You control access** - Revoke anytime via GitHub settings

### Best Practices

1. **Revoke when done** - If you no longer use the skill, revoke access
2. **Monitor access** - Check GitHub → Settings → Applications periodically
3. **Scope limitation** - The skill only requests necessary scopes (repo, read:org)

---

## Comparison: Device Flow vs OAuth App

| Feature | Device Flow (This Skill) | OAuth App |
|---------|------------------------|-----------|
| **Setup** | None - works out of the box | Create OAuth app + config |
| **User experience** | Enter code at github.com/login/device | Browser redirect + callback |
| **Secrets** | None (public client_id only) | client_secret required |
| **Distribution** | ✅ Simple - no configuration | ❌ Complex - share secrets |
| **Private repos** | ✅ Yes | ✅ Yes |
| **Rate limits** | Individual per user | Shared if same OAuth app |

**Device flow is perfect for CLI tools and skills** - GitHub CLI uses it too!

---

## Comparison: GitHub vs Local Codebase

| Feature | GitHub Device Flow | Local Codebase |
|---------|-------------------|----------------|
| **Setup** | One-time device auth | Just provide path |
| **Authentication** | First use only | None |
| **Private repos** | ✅ Yes | ✅ Yes (if local clone) |
| **Always latest** | ✅ Fetches from GitHub | ⚠️ Manual git pull |
| **Network required** | ✅ Yes | ❌ No |
| **Rate limits** | ⚠️ 5,000 req/hour | ❌ None |
| **Multiple machines** | ✅ Re-auth on each | ✅ Works anywhere |

---

## How Device Flow Works (Technical)

### Authentication Flow

1. **Request device code:**
   ```
   POST https://github.com/login/device/code
   {
     "client_id": "Iv23liPRDGenerator",
     "scope": "repo read:org"
   }
   ```

2. **Response:**
   ```json
   {
     "device_code": "...",
     "user_code": "XXXX-XXXX",
     "verification_uri": "https://github.com/login/device",
     "expires_in": 900,
     "interval": 5
   }
   ```

3. **User authorizes** at github.com/login/device

4. **Poll for token:**
   ```
   POST https://github.com/login/oauth/access_token
   {
     "client_id": "Iv23liPRDGenerator",
     "device_code": "...",
     "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
   }
   ```

5. **Receive token:**
   ```json
   {
     "access_token": "gho_xxxxxxxxxxxx",
     "token_type": "bearer",
     "scope": "repo read:org"
   }
   ```

6. **Store in Keychain** for future use

### Repository Fetching

The skill:
- ✅ Fetches latest commit from default branch
- ✅ Downloads all files recursively
- ✅ Respects .gitignore patterns
- ✅ Handles binary files (skips from analysis)
- ✅ Works with private repositories
- ✅ Supports organization repositories
- ✅ Rate limit aware (GitHub API limits)

### RAG Integration

After downloading from GitHub:
1. Files treated identical to local codebase
2. Indexed into PostgreSQL with vector embeddings
3. Hybrid search (vector + BM25) enabled
4. Context retrieved for PRD generation

---

## Example: Complete Flow

```
User: "Generate a PRD for adding real-time notifications to my app.
       Repository: https://github.com/mycompany/webapp"

Skill:
🔐 GitHub Authentication Required

📝 Please visit: https://github.com/login/device

🔑 Enter code: A1B2-C3D4

⏱️  Code expires in 15 minutes

🌐 Browser opened - paste code there
⏳ Waiting for authorization...

[User enters code in browser and clicks Authorize]

✅ Authenticated as @johndoe
✅ Access token stored securely in macOS Keychain

📦 Fetching repository: mycompany/webapp
   Repository: webapp (JavaScript)
   Default branch: main
   Last commit: feat: update user dashboard (2 hours ago)
   Private: Yes

📥 Downloading files...
   ├── src/ (234 files)
   ├── tests/ (89 files)
   ├── docs/ (12 files)
   └── config/ (8 files)

✅ Downloaded 343 files (12.4 MB)
⏭️  Skipped 15 binary files (.png, .jpg, .woff)
⏭️  Respecting .gitignore (node_modules, .env)

📊 Initializing RAG database...
✅ RAG database ready (PostgreSQL + pgvector)

📊 Indexing codebase for analysis...
   Chunking files... 343 files → 2,147 chunks
   Generating embeddings... 2,147/2,147 [████████████] 100%
   Creating vector index... Done (HNSW)
   Building BM25 index... Done

✅ Indexing complete (3m 24s)

🔍 Searching codebase for relevant patterns...

Query: "WebSocket implementation"
📄 src/services/websocket.service.js (similarity: 0.94)
📄 src/hooks/useWebSocket.js (similarity: 0.91)
📄 src/config/socket.config.js (similarity: 0.88)

💭 Clarification Questions

Based on analyzing the GitHub repository mycompany/webapp, I found:

**Current Architecture:**
- ✅ WebSocket server (Socket.IO) in src/services/websocket.service.js
- ✅ Redux store with notifications slice
- ⚠️  No real-time notification delivery currently

**Questions:**
1. Should notifications reuse the existing WebSocket connection?
   a) Reuse (Recommended)
   b) Create separate connection

[PRD generation continues...]
```

---

## Summary

**Setup:**
- None required - device flow works out of the box

**Usage:**
1. Provide GitHub URL in PRD request
2. First time: Enter code at github.com/login/device
3. Skill downloads repository and indexes with RAG
4. Subsequent uses: Automatic with stored token

**Security:**
- Token stored in macOS Keychain (encrypted)
- Read-only access to repositories
- Revocable anytime via GitHub settings
- Code stays local (privacy-first)

---

**GitHub integration ready!** 🚀

You can now analyze private repositories, fetch latest code automatically, and use all RAG features with GitHub-hosted code.

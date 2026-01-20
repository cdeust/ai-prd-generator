# GitHub CLI Integration Guide

## Overview

The skill can fetch and analyze codebases directly from GitHub repositories using **GitHub CLI (`gh`) authentication**. This allows you to access private repositories using your existing GitHub account.

## Key Benefits

✅ **Uses GitHub CLI** - Leverages the official `gh` tool
✅ **Simple authentication** - One command: `gh auth login`
✅ **No secrets to manage** - Token stored securely by GitHub CLI
✅ **Works with private repos** - Full access to your repositories
✅ **Organization support** - Access org repositories you're a member of
✅ **Token reuse** - Authenticate once, use everywhere

---

## Prerequisites

### Install GitHub CLI

**macOS:**
```bash
brew install gh
```

**Linux:**
```bash
# Debian/Ubuntu
sudo apt install gh

# Fedora/CentOS
sudo dnf install gh

# Arch
sudo pacman -S github-cli
```

**Verify installation:**
```bash
gh --version
# Should show: gh version 2.x.x
```

---

## Authentication

### First-Time Setup

Run GitHub CLI authentication:

```bash
gh auth login
```

**Interactive prompts:**
```
? What account do you want to log into?
  > GitHub.com

? What is your preferred protocol for Git operations?
  > HTTPS

? Authenticate Git with your GitHub credentials?
  > Yes

? How would you like to authenticate GitHub CLI?
  > Login with a web browser
```

**In your browser:**
1. GitHub opens automatically
2. Authorize GitHub CLI
3. Done!

**Verification:**
```bash
gh auth status
# ✓ Logged in to github.com as username
# ✓ Token: *******************
```

### Subsequent Uses

Once authenticated with `gh auth login`, the skill automatically uses your stored token.

```bash
# Check authentication status
gh auth status

# Refresh token (if expired)
gh auth refresh
```

---

## Usage with Skill

### Basic GitHub Repository Analysis

```
User: "Generate a PRD for adding notifications.
       Repository: https://github.com/mycompany/webapp"

Skill:
✅ GitHub CLI authenticated as @johndoe
📦 Fetching mycompany/webapp...
   Repository: webapp (JavaScript)
   Default branch: main
   Last commit: feat: update dashboard (2 hours ago)
   Private: Yes

📥 Downloading files...
   ├── src/ (234 files)
   ├── tests/ (89 files)
   └── config/ (8 files)

✅ Downloaded 343 files (12.4 MB)
📊 Indexing with RAG...
✅ RAG ready - Hybrid search enabled

🔍 Analyzing codebase for notification patterns...
```

### Multiple Repositories

```
User: "Compare authentication patterns across:
- https://github.com/mycompany/api-backend
- https://github.com/mycompany/web-frontend
- https://github.com/mycompany/mobile-app"

Skill:
✅ GitHub CLI authenticated
📦 Fetching 3 repositories...
✅ api-backend: 892 files
✅ web-frontend: 456 files
✅ mobile-app: 623 files

📊 Indexing 1,971 files with RAG...
✅ Hybrid search ready across all 3 codebases

🔍 Finding authentication patterns...
```

---

## Configuration

### Skill Configuration

Edit `skill-config.json`:

```json
{
  "integrations": {
    "github": {
      "enabled": true,
      "auth_method": "gh_cli",
      "scopes": ["repo", "read:org"]
    }
  }
}
```

### GitHub CLI Configuration

**View current configuration:**
```bash
gh config list
```

**Common settings:**
```bash
# Set default protocol
gh config set git_protocol https

# Set default editor
gh config set editor vim

# Set pager
gh config set pager less
```

---

## Token Management

### Token Storage

GitHub CLI stores tokens securely:
- **macOS**: Keychain
- **Linux**: Secret Service API or encrypted file
- **Windows**: Credential Manager

**Token location:**
```bash
# View token (requires password)
gh auth token
```

### Revoke Access

**Option 1: Via GitHub CLI**
```bash
gh auth logout
```

**Option 2: Via GitHub Web**
1. Go to **GitHub Settings** → **Developer settings** → **Personal access tokens**
2. Find tokens starting with `gho_`
3. Click **Delete**

**Option 3: Via GitHub Settings**
1. **Settings** → **Applications** → **Authorized GitHub Apps**
2. Find **GitHub CLI**
3. Click **Revoke**

### Re-authenticate

```bash
# Logout
gh auth logout

# Login again
gh auth login
```

---

## Troubleshooting

### GitHub CLI Not Found

**Problem**: `gh: command not found`

**Solution**:
```bash
# Install GitHub CLI
brew install gh

# Verify
gh --version
```

### Not Authenticated

**Problem**: `gh: To use GitHub API, you must be authenticated`

**Solution**:
```bash
# Authenticate
gh auth login

# Check status
gh auth status
```

### Token Expired

**Problem**: `gh: GitHub token expired`

**Solution**:
```bash
# Refresh token
gh auth refresh -h github.com -s repo,read:org

# Or re-authenticate
gh auth logout
gh auth login
```

### Repository Access Denied

**Problem**: `Repository not found or access denied`

**Possible causes:**
- Repository doesn't exist
- Repository is private and you don't have access
- Token lacks required scopes

**Solution**:
```bash
# Check repository exists
gh repo view owner/repo

# Check your access
gh auth status

# Refresh with correct scopes
gh auth refresh -h github.com -s repo,read:org
```

### Private Repository Not Accessible

**Problem**: Can access public repos but not private

**Solution**:
```bash
# Ensure you have `repo` scope
gh auth refresh -h github.com -s repo

# Verify scopes
gh auth status
# Look for: Token scopes: repo, read:org
```

### Organization Repositories

**Problem**: Can't access organization repositories

**Solution**:
```bash
# Add read:org scope
gh auth refresh -h github.com -s repo,read:org

# Verify org membership
gh api user/orgs
```

---

## Security & Privacy

### What GitHub CLI Can Access

With `repo` scope:
- ✅ Read all public and private repositories you have access to
- ✅ Read commit history and status
- ✅ Read repository metadata
- ❌ Cannot write, delete, or modify repositories (read-only)
- ❌ Cannot access your password or other credentials

With `read:org` scope:
- ✅ Read organization membership
- ✅ Read organization repositories list
- ❌ Cannot modify organization settings

### Data Privacy

- ✅ **Token stored locally** - Encrypted by OS
- ✅ **Code stays local** - Downloaded to your machine only
- ✅ **No data uploaded** - Code never sent to external servers (except AI provider for embeddings)
- ✅ **You control access** - Revoke anytime via `gh auth logout`

### Best Practices

1. **Use HTTPS protocol** - More secure than SSH for CLI tools
2. **Minimal scopes** - Only request `repo` and `read:org`
3. **Regular token refresh** - Keep tokens up to date
4. **Monitor access** - Check `gh auth status` periodically
5. **Revoke when done** - Logout if you no longer use the skill

---

## Advanced Usage

### Working with Multiple Accounts

```bash
# Login to enterprise account
gh auth login -h github.enterprise.com

# Login to personal account
gh auth login -h github.com

# Switch between accounts
gh auth switch
```

### Using with Private GitHub Enterprise

```bash
# Authenticate to enterprise instance
gh auth login -h github.mycompany.com

# Verify
gh auth status -h github.mycompany.com
```

### API Rate Limits

```bash
# Check rate limit
gh api rate_limit

# Response:
# {
#   "rate": {
#     "limit": 5000,
#     "remaining": 4999,
#     "reset": 1642687200
#   }
# }
```

**Authenticated rate limit**: 5,000 requests/hour per user

---

## Comparison: GitHub CLI vs Device Flow

| Feature | GitHub CLI (This Skill) | Device Flow |
|---------|------------------------|-------------|
| **Setup** | Install gh CLI + login | No setup needed |
| **Authentication** | Interactive browser login | Enter code at github.com/login/device |
| **Token storage** | Managed by gh CLI | Manual keychain management |
| **Reliability** | ✅ Stable | ⚠️ Experimental (not officially supported) |
| **Private repos** | ✅ Yes | ⚠️ May work but unreliable |
| **Organization repos** | ✅ Yes | ⚠️ Limited support |
| **Token refresh** | `gh auth refresh` | Manual re-authentication |

**GitHub CLI is the recommended approach** - Official, stable, and fully supported by GitHub.

---

## Example: Complete Workflow

```bash
# 1. Install GitHub CLI (one-time)
brew install gh

# 2. Authenticate (one-time)
gh auth login
# Follow interactive prompts

# 3. Verify authentication
gh auth status
# ✓ Logged in to github.com as johndoe

# 4. Use skill with GitHub repository
# In Claude Code:
"Generate a PRD for real-time notifications.
 Repository: https://github.com/mycompany/webapp"

# 5. Skill automatically uses gh token
# ✅ GitHub CLI authenticated as @johndoe
# 📦 Fetching repository...
# 📊 Indexing with RAG...
# 🎯 Generating PRD...

# Done! Token persists for future requests.
```

---

## Summary

**Setup (one-time):**
```bash
brew install gh
gh auth login
```

**Usage:**
- Provide GitHub URL to skill
- Skill automatically uses `gh` token
- No manual token management needed

**Token management:**
```bash
gh auth status      # Check authentication
gh auth refresh     # Refresh token
gh auth logout      # Revoke access
```

---

**GitHub integration ready with GitHub CLI!** 🚀

Secure, reliable, and officially supported by GitHub.

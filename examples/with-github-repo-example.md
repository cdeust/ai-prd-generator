# Example: PRD with GitHub Repository Integration

## User Request

```
Generate a PRD for adding real-time notifications.

Repository: https://github.com/mycompany/webapp
Branch: main

Analyze:
- Existing WebSocket setup
- State management patterns
- API endpoint structure
```

## First-Time GitHub Authentication (Device Flow)

```
Skill:
🔐 GitHub Authentication Required

📝 Please visit: https://github.com/login/device

🔑 Enter code: A1B2-C3D4

⏱️  Code expires in 15 minutes

🌐 Browser opened - paste code there
⏳ Waiting for authorization...
```

**In Browser:**
```
GitHub Device Activation

Enter the code displayed in your terminal:

[A1B2-C3D4]

[Continue]
```

**After entering code:**
```
GitHub Authorization

AI PRD Generator by @yourusername
wants to access your GitHub account

This application will be able to:
✓ Read your public and private repositories
✓ Read organization membership

[Authorize AI PRD Generator] [Cancel]
```

**User clicks "Authorize"**

**Back in Terminal:**
```
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

📊 RAG Summary:
   - Files indexed: 343
   - Code chunks: 2,147
   - Vector embeddings: 2,147
   - Database size: 187MB
   - Search ready: Vector + BM25 hybrid

🔍 Searching codebase for relevant patterns...

Query: "WebSocket implementation"
📄 src/services/websocket.service.js (similarity: 0.94)
📄 src/hooks/useWebSocket.js (similarity: 0.91)
📄 src/config/socket.config.js (similarity: 0.88)

Query: "State management"
📄 src/store/index.js (similarity: 0.93) - Redux store setup
📄 src/reducers/notifications.reducer.js (similarity: 0.90)
📄 src/actions/notifications.actions.js (similarity: 0.87)

Query: "API endpoints"
📄 src/api/client.js (similarity: 0.92) - Axios client setup
📄 src/api/notifications.api.js (similarity: 0.91)
📄 backend/routes/notifications.js (similarity: 0.89)

✅ Found 9 highly relevant files for context

💭 Clarification Questions

Based on analyzing the GitHub repository mycompany/webapp, I found:

**Current Architecture:**
- ✅ WebSocket server (Socket.IO) in src/services/websocket.service.js
- ✅ Redux store with notifications slice
- ✅ REST API: GET /api/notifications, POST /api/notifications/mark-read
- ⚠️  No real-time notification delivery currently

**Questions:**

1. **WebSocket Reuse** - Your Socket.IO setup (src/services/websocket.service.js)
   currently handles chat messages only. Should notifications:
   a) Reuse the same WebSocket connection (add new event handlers)
   b) Create a separate WebSocket connection for notifications

   Recommended: (a) - Reuse connection (single persistent connection)

2. **Redux Integration** - Your notifications.reducer.js stores notifications
   in Redux state. Should real-time notifications:
   a) Automatically dispatch to Redux when received via WebSocket
   b) Require manual fetch after WebSocket event

   Recommended: (a) - Auto-dispatch for immediate UI update

3. **Notification Types** - Current code shows "chat" and "system" types.
   What additional types do you need?
   - [ ] Mentions (@username)
   - [ ] Likes/reactions
   - [ ] Comments on your content
   - [ ] System alerts
   - [ ] Other: _______

4. **Persistence** - I see PostgreSQL database (from backend/models/notification.js).
   Should notifications:
   a) Persist in DB and sync across devices/sessions
   b) Be ephemeral (real-time only, no persistence)

   Recommended: (a) - Persist for history and multi-device sync

5. **Backend Location** - Your backend/ folder has Express routes. Should I:
   a) Extend existing backend/routes/notifications.js
   b) Create new microservice for real-time notifications

   Recommended: (a) - Extend existing (simpler architecture)

Current confidence: 78%
Target: 90%
```

## After User Answers

```
User Answers:
1. Reuse WebSocket connection (a)
2. Auto-dispatch to Redux (a)
3. Add: Mentions, Comments, System alerts
4. Persist in DB (a)
5. Extend existing backend (a)

Skill:
✅ Confidence increased: 78% → 93%
✅ All clarifications answered

🎯 Generating PRD with GitHub codebase context...
```

## Generated PRD (Excerpts)

```markdown
# Real-Time Notifications System

**Confidence Score**: 0.93/1.00
**Generated**: 2026-01-20
**GitHub Repository**: mycompany/webapp (main branch)
**Files Analyzed**: 343 files (9 highly relevant)

## 4. Technical Specification

### Current Architecture (from GitHub repo analysis)

**WebSocket Infrastructure** (src/services/websocket.service.js:15-42):
```javascript
// Existing Socket.IO setup
const io = require('socket.io')(server, {
  cors: { origin: process.env.CLIENT_URL }
})

io.on('connection', (socket) => {
  socket.on('chat:message', handleChatMessage)
  socket.on('chat:typing', handleTyping)
})
```

**Current Limitation:** WebSocket only handles chat events, not notifications.

**Redux Store** (src/store/index.js:8):
```javascript
const store = configureStore({
  reducer: {
    auth: authReducer,
    chat: chatReducer,
    notifications: notificationsReducer  // EXISTS but not connected to real-time
  }
})
```

**API Endpoints** (backend/routes/notifications.js:12-24):
```javascript
// Existing REST API (polling-based)
router.get('/api/notifications', authenticate, getNotifications)
router.post('/api/notifications/mark-read', authenticate, markAsRead)
```

**Current Limitation:** REST API requires polling, no push delivery.

### Proposed Architecture (Extends GitHub codebase)

```
Frontend (React + Redux)
  ↓
WebSocket Client (EXISTING - extend)
  ├── chat:message (existing)
  ├── chat:typing (existing)
  ├── notification:new (NEW)
  ├── notification:read (NEW)
  └── notification:deleted (NEW)
  ↓ wss://
WebSocket Server (EXISTING - extend)
  ↓
Notification Service (NEW)
  ↓
PostgreSQL (EXISTING database)
```

### Integration Points

**1. Extend WebSocket Service** (src/services/websocket.service.js)

**Current code (lines 15-42):**
```javascript
io.on('connection', (socket) => {
  socket.on('chat:message', handleChatMessage)
  socket.on('chat:typing', handleTyping)
})
```

**Proposed extension:**
```javascript
io.on('connection', (socket) => {
  const userId = socket.handshake.auth.userId

  // Join user's personal notification room
  socket.join(`user:${userId}:notifications`)

  // EXISTING chat handlers (unchanged)
  socket.on('chat:message', handleChatMessage)
  socket.on('chat:typing', handleTyping)

  // NEW notification handlers
  socket.on('notification:subscribe', () => {
    sendUnreadNotifications(socket, userId)
  })

  socket.on('notification:mark-read', (notificationId) => {
    markNotificationAsRead(userId, notificationId)
    socket.to(`user:${userId}:notifications`).emit('notification:read', { id: notificationId })
  })
})
```

**2. Extend Redux Reducer** (src/reducers/notifications.reducer.js)

**Current state (from GitHub repo - lines 5-9):**
```javascript
const initialState = {
  items: [],
  unreadCount: 0,
  loading: false
}
```

**Proposed enhancement:**
```javascript
const initialState = {
  items: [],
  unreadCount: 0,
  loading: false,
  isConnected: false,        // NEW: WebSocket connection status
  lastSync: null,             // NEW: Last sync timestamp
  realtimeEnabled: true       // NEW: User preference
}

// NEW action
case 'notifications/receivedRealtime': {
  return {
    ...state,
    items: [action.payload, ...state.items],
    unreadCount: state.unreadCount + 1,
    lastSync: new Date().toISOString()
  }
}
```

**3. Backend WebSocket Extension** (backend/routes/notifications.js)

**Add real-time delivery function:**
```javascript
// NEW: Send notification via WebSocket
async function sendRealtimeNotification(userId, notification) {
  // Save to database (existing table)
  const saved = await db.notifications.create(notification)

  // Send via WebSocket if user online
  io.to(`user:${userId}:notifications`).emit('notification:new', saved)

  // Fallback: Queue for push notification if offline
  if (!isUserOnline(userId)) {
    await queuePushNotification(userId, saved)
  }

  return saved
}
```

### Database Schema (EXISTING - No changes needed)

**From backend/models/notification.js (lines 8-22):**
```javascript
const Notification = db.define('notification', {
  id: { type: DataTypes.UUID, primaryKey: true },
  userId: { type: DataTypes.UUID, allowNull: false },
  type: { type: DataTypes.ENUM('chat', 'system'), allowNull: false },
  message: { type: DataTypes.TEXT, allowNull: false },
  isRead: { type: DataTypes.BOOLEAN, default: false },
  createdAt: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
})
```

**Proposed migration (extend type enum):**
```sql
ALTER TYPE notification_type ADD VALUE 'mention';
ALTER TYPE notification_type ADD VALUE 'comment';
ALTER TYPE notification_type ADD VALUE 'system_alert';
```

## Appendix

### B. GitHub Repository Context

**Repository:** https://github.com/mycompany/webapp
**Branch:** main
**Last Commit:** feat: update user dashboard (2 hours ago by @jane)
**Language:** JavaScript (React + Node.js)
**Files Analyzed:** 343 total, 9 highly relevant

**Key Files:**

1. **src/services/websocket.service.js** (15-42)
   - Socket.IO client connection
   - Current events: chat:message, chat:typing
   - Auth: JWT token in handshake
   - Can extend with notification handlers

2. **src/reducers/notifications.reducer.js** (5-35)
   - Redux slice for notifications
   - State: items[], unreadCount
   - Actions: FETCH_NOTIFICATIONS, MARK_AS_READ
   - Can add: RECEIVED_REALTIME action

3. **backend/routes/notifications.js** (12-56)
   - REST endpoints: GET /api/notifications
   - Database: PostgreSQL (notification table)
   - Auth: Express middleware
   - Can add: sendRealtimeNotification()

4. **src/store/index.js** (8)
   - Redux store configuration
   - Already includes notifications reducer
   - No changes needed

5. **backend/models/notification.js** (8-22)
   - Sequelize model
   - Fields: id, userId, type, message, isRead
   - Can extend: Add new notification types

**Architecture Decisions Based on GitHub Analysis:**
- ✅ **Reuse WebSocket** - Don't create new connection (existing Socket.IO works)
- ✅ **Extend Redux** - notifications reducer already exists
- ✅ **Keep REST API** - Maintain as fallback for offline mode
- ✅ **Use existing DB** - notification table schema sufficient
- ✅ **No breaking changes** - All extensions backward compatible

**RAG Search Performance:**
```
Hybrid Search Results (vector + BM25):
- Vector search: 8 files (similarity > 0.85)
- BM25 search: 12 files (keyword match)
- Reciprocal Rank Fusion: 9 unique files (α=0.7)
- Total context: 2,847 lines of code analyzed
```

**Confidence Boost from GitHub RAG:**
- Without codebase: 65% (general knowledge)
- With GitHub repo: 93% (actual architecture)
- **+28% confidence** from real codebase analysis
```

## Subsequent Requests (Token Reused)

```
User: "Now generate PRD for adding payment processing to the same app"

Skill:
✅ GitHub already authenticated (@johndoe)
✅ Using cached repository: mycompany/webapp
📊 RAG database ready (343 files indexed)

🔍 Searching for payment-related code...
📄 src/services/payment.service.js (similarity: 0.96)
📄 backend/routes/checkout.js (similarity: 0.94)
📄 src/components/PaymentForm.jsx (similarity: 0.92)

Found existing Stripe integration! Analyzing...
```

## Notes

- **First time:** Device flow authentication required (enter code in browser)
- **Subsequent:** Token reused automatically from Keychain
- **RAG indexing:** One-time per repository (cached)
- **Updates:** Re-fetch and re-index if repository changes
- **Private repos:** Fully supported with device flow token
- **Confidence:** Much higher with real codebase context (93% vs 65%)
- **No OAuth app:** Device flow works out of the box (like GitHub CLI)

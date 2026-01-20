# Example: PRD with Codebase Analysis (RAG)

## User Request

```
Generate a PRD for adding real-time notifications to my app.

Codebase: /Users/me/my-react-app

Analyze:
- Existing WebSocket setup (if any)
- State management patterns (Redux, Context, etc.)
- API endpoint structure
- Current notification mechanisms
```

## Expected Workflow

1. **Automatic RAG Database Setup** (first time only):
   ```
   ✅ Checking for RAG database...
   📦 No database found - setting up automatically
   🐳 Pulling PostgreSQL + pgvector image...
   ✅ Started container: ai-prd-rag-db on port 5433
   ✅ Created database: ai_prd_rag
   ✅ Enabled pgvector extension
   ✅ RAG database ready!
   ```

2. **Codebase Indexing** (first time or when updated):
   ```
   📊 Indexing codebase: /Users/me/my-react-app

   Scanning files... Found 247 files (respecting .gitignore)
   Chunking files... Created 1,847 chunks
   Generating embeddings... 1,847/1,847 [████████████] 100%
   Creating vector index... Done
   Building BM25 index... Done

   ✅ Indexing complete (2m 14s)

   Summary:
   - Files indexed: 247
   - Code chunks: 1,847
   - Vector embeddings: 1,847
   - Database size: 127MB
   ```

3. **RAG Search During Analysis**:
   ```
   🔍 Searching codebase for relevant patterns...

   Query: "WebSocket implementation"
   📄 src/services/websocket.ts (similarity: 0.94)
   📄 src/hooks/useWebSocket.ts (similarity: 0.89)
   📄 src/config/socket.config.ts (similarity: 0.87)

   Query: "State management"
   📄 src/store/index.ts (similarity: 0.92) - Redux store setup
   📄 src/reducers/notifications.ts (similarity: 0.88) - Existing notifications reducer
   📄 src/actions/notifications.ts (similarity: 0.86)

   Query: "API endpoints"
   📄 src/api/client.ts (similarity: 0.91) - API base URL and auth
   📄 src/api/notifications.ts (similarity: 0.90) - Existing notification APIs

   ✅ Found 8 relevant files for context
   ```

4. **Clarification Questions** (informed by codebase):
   ```
   Based on analyzing your React app, I found:
   - ✅ Existing WebSocket setup in src/services/websocket.ts
   - ✅ Redux store with notifications reducer
   - ✅ REST API endpoints for notifications
   - ⚠️  No real-time notification delivery currently

   Clarification needed:

   1. **WebSocket Integration** - You have WebSocket code but it's only used for chat. Should notifications use the same WebSocket connection or create a separate one?

   2. **Redux State** - Your notifications reducer stores a list. Should real-time notifications automatically update this Redux state?

   3. **API Endpoints** - I see GET /api/notifications and POST /api/notifications/mark-read. Should we add a WebSocket endpoint or extend the existing REST API?

   4. **Notification Types** - Current code shows chat messages and system alerts. What new notification types do you need? (mentions, likes, comments, etc.)

   5. **Persistence** - Should notifications persist in database and sync across devices, or just be ephemeral real-time alerts?

   Current confidence: 73% (codebase context helps!)
   Target: 90%
   ```

5. **PRD Generation with RAG Context**:

## Sample Output (Relevant Sections)

```markdown
# Real-Time Notifications System

**Confidence Score**: 0.94/1.00
**Generated**: 2026-01-20
**Codebase Analyzed**: /Users/me/my-react-app (247 files, 1,847 chunks)

## 4. Technical Specification

### Architecture

**Current State** (from codebase analysis):
- ✅ WebSocket server: `ws://localhost:3001` (src/services/websocket.ts)
- ✅ Redux store with notifications slice (src/reducers/notifications.ts)
- ✅ REST API: `/api/notifications` (src/api/notifications.ts)
- ❌ No real-time notification delivery

**Proposed Architecture**:
```
Frontend (React + Redux)
  ↓
WebSocket Client (existing connection)
  ↓ wss://
WebSocket Server (extend existing)
  ↓
Notification Service (new)
  ↓
PostgreSQL (existing DB)
```

### Integration Points

**1. Extend Existing WebSocket Handler**

**Current code** (src/services/websocket.ts:45):
```typescript
// Existing WebSocket setup
const socket = io('ws://localhost:3001', {
  auth: { token: getAuthToken() }
})

socket.on('chat:message', handleChatMessage)
```

**Proposed change**:
```typescript
// Add notification handler
socket.on('notification:new', handleNewNotification)
socket.on('notification:read', handleNotificationRead)
socket.on('notification:deleted', handleNotificationDeleted)

function handleNewNotification(notification: Notification) {
  // Dispatch to Redux (integrate with existing notifications reducer)
  store.dispatch(addNotification(notification))

  // Show toast notification
  showToast(notification)
}
```

**2. Enhance Redux Reducer**

**Current reducer** (src/reducers/notifications.ts:12):
```typescript
// Existing state shape
interface NotificationsState {
  items: Notification[]
  unreadCount: number
}
```

**Proposed enhancement**:
```typescript
// Add real-time tracking
interface NotificationsState {
  items: Notification[]
  unreadCount: number
  isConnected: boolean          // ← NEW: WebSocket status
  lastSync: Date | null          // ← NEW: Last sync timestamp
  realtimeEnabled: boolean       // ← NEW: User preference
}

// Add reducer cases
case 'notification/receivedRealtime': {
  // Auto-update from WebSocket
  return {
    ...state,
    items: [action.payload, ...state.items],
    unreadCount: state.unreadCount + 1
  }
}
```

**3. Backend WebSocket Endpoint**

**Extend existing WebSocket server** (backend/server.ts:78):
```typescript
// Existing WebSocket setup
io.on('connection', (socket) => {
  const userId = socket.handshake.auth.userId

  // Join user's notification room
  socket.join(`user:${userId}:notifications`)  // ← NEW

  // Existing chat handlers
  socket.on('chat:send', handleChatMessage)

  // NEW: Notification handlers
  socket.on('notification:subscribe', () => {
    // Send initial unread notifications
    sendUnreadNotifications(socket, userId)
  })
})
```

**4. Notification Delivery Service** (new file):
```typescript
// backend/services/NotificationService.ts
export class NotificationService {
  async sendNotification(userId: string, notification: Notification) {
    // Save to database (existing DB connection)
    await db.notifications.create(notification)

    // Send via WebSocket if user online
    io.to(`user:${userId}:notifications`).emit('notification:new', notification)

    // Fallback: Queue for push notification if offline
    if (!isUserOnline(userId)) {
      await queuePushNotification(userId, notification)
    }
  }
}
```

### API Endpoints

**Existing endpoints** (keep as fallback):
- `GET /api/notifications` - Fetch all notifications
- `POST /api/notifications/mark-read` - Mark as read

**New WebSocket events**:
- `notification:subscribe` - Client requests real-time notifications
- `notification:new` - Server → Client (new notification)
- `notification:read` - Server → Client (notification marked read)
- `notification:deleted` - Server → Client (notification deleted)

### Data Models

**Existing model** (src/types/notification.ts:5):
```typescript
interface Notification {
  id: string
  userId: string
  type: 'chat' | 'system'
  message: string
  createdAt: Date
  isRead: boolean
}
```

**Proposed enhancement**:
```typescript
interface Notification {
  id: string
  userId: string
  type: 'chat' | 'system' | 'mention' | 'like' | 'comment'  // ← EXTENDED
  message: string
  createdAt: Date
  isRead: boolean
  data?: Record<string, any>     // ← NEW: Type-specific data
  priority: 'low' | 'normal' | 'high'  // ← NEW: Delivery priority
  deliveredAt?: Date             // ← NEW: Real-time delivery timestamp
}
```

## Appendix

### B. Codebase Context (RAG Analysis)

**Files Analyzed**: 247
**Relevant Files**: 8

**Key Findings**:

1. **WebSocket Infrastructure** (src/services/websocket.ts)
   - Already using Socket.IO client
   - Connected to ws://localhost:3001
   - Auth token included in handshake
   - → Can extend with notification handlers

2. **State Management** (src/reducers/notifications.ts)
   - Redux store already has notifications slice
   - Current shape: items[], unreadCount
   - Actions: fetchNotifications, markAsRead
   - → Can add real-time actions

3. **API Layer** (src/api/notifications.ts)
   - REST endpoints for fetch and mark-read
   - Uses axios with auth interceptor
   - Error handling with toast notifications
   - → Keep as fallback for offline mode

4. **Backend WebSocket** (backend/server.ts)
   - Socket.IO server on port 3001
   - JWT authentication in handshake
   - Rooms for chat channels
   - → Can add notification rooms

5. **Database** (backend/models/notification.ts)
   - Existing notifications table in PostgreSQL
   - Schema matches frontend model
   - Indexes on userId and createdAt
   - → No schema changes needed

**Architecture Decisions Based on Codebase**:
- ✅ Use existing WebSocket connection (don't create new one)
- ✅ Extend Redux notifications reducer (don't create new slice)
- ✅ Keep REST API as fallback (offline/initial load)
- ✅ Add rooms to existing Socket.IO server
- ✅ No database migration needed

**RAG Search Results**:
```
Vector Search (similarity > 0.85): 8 files
Full-Text Search (BM25): 12 files
Hybrid Rank Fusion (α=0.7): 8 unique files used
```

**Confidence Boost from RAG**: +21%
- Without codebase: 73% → With codebase: 94%
```

## Notes

- **RAG automatically indexed** the codebase on first use
- **Hybrid search** (vector + BM25) found most relevant files
- **Technical spec respects** existing architecture patterns
- **No breaking changes** - extends existing code
- **Confidence much higher** due to codebase context (94% vs typical 73%)

# SwapTunes — Realtime Channels
> Platform: **Supabase Realtime** (Postgres Change Data Capture over WebSocket)  
> Flutter SDK: `supabase_flutter`  
> All channels use `PostgresChangeEvent` listeners

---

## How Supabase Realtime Works

```
Flutter subscribes to channel
         │
         ▼
User or backend performs DB write (INSERT/UPDATE)
         │
         ▼
Postgres detects change via logical replication (CDC)
         │
         ▼
Supabase Realtime broadcasts change to all subscribers
         │
         ▼
Flutter callback fires with new payload
         │
         ▼
UI updates instantly (no polling)
```

---

## Channel 1 — Live Messaging

**Channel name:** `messages:conversation_id=eq.<convId>`  
**Table:** `messages`  
**Subscribe:** When user opens a chat screen  
**Unsubscribe:** When user leaves the chat screen (`dispose`)

### Events
| Event | Trigger | Action |
|-------|---------|--------|
| `INSERT` | New message sent by either participant | Append message to chat list |
| `UPDATE` | Message `is_read` updated | Update read receipts |

### Flutter Code
```dart
final channel = supabase.channel('messages:$convId')
  ..onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'messages',
    filter: PostgresChangeFilter(
      type: FilterType.eq,
      column: 'conversation_id',
      value: convId,
    ),
    callback: (payload) {
      final newMessage = Message.fromJson(payload.newRecord);
      setState(() => _messages.insert(0, newMessage));
    },
  )
  ..subscribe();

// On dispose:
supabase.removeChannel(channel);
```

### Notes
- Only subscribe to the conversation the user is **currently viewing**
- On screen open: load history via `GET /conversations/:id/messages` first, then subscribe for new messages
- Mark messages read via `PATCH /conversations/:id/read` when screen is focused

---

## Channel 2 — Notifications (Bell Badge)

**Channel name:** `notifications:user_id=eq.<userId>`  
**Table:** `notifications`  
**Subscribe:** On app start, after authentication  
**Unsubscribe:** On logout

### Events
| Event | Trigger | Action |
|-------|---------|--------|
| `INSERT` | New notification created | Increment bell badge count |

### Flutter Code
```dart
final channel = supabase.channel('notifications:$userId')
  ..onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'notifications',
    filter: PostgresChangeFilter(
      type: FilterType.eq,
      column: 'user_id',
      value: userId,
    ),
    callback: (payload) {
      ref.read(notificationBadgeProvider.notifier).increment();
    },
  )
  ..subscribe();
```

### Notification Types Received
| `type` value | Meaning | reference_id points to |
|---|---|---|
| `like` | Someone liked your post | `posts.id` |
| `comment` | Someone commented on your post | `posts.id` |
| `follow` | Someone followed you | `users.id` (actor) |
| `collab` | Someone started a conversation on your collab | `collaborations.id` |
| `message` | New message received | `conversations.id` |

---

## Channel 3 — Inbox Conversation List

**Channel name:** `conversations:user_one_id=eq.<userId>`  
**Table:** `conversations`  
**Subscribe:** When user is on the Inbox screen  
**Unsubscribe:** When user leaves Inbox

### Events
| Event | Trigger | Action |
|-------|---------|--------|
| `UPDATE` | `last_message_at` updated when new message sent | Re-sort conversation list to show latest at top |

### Flutter Code
```dart
final channel = supabase.channel('inbox:$userId')
  ..onPostgresChanges(
    event: PostgresChangeEvent.update,
    schema: 'public',
    table: 'conversations',
    filter: PostgresChangeFilter(
      type: FilterType.eq,
      column: 'user_one_id',
      value: userId,
    ),
    callback: (payload) {
      // Refresh conversation list
      ref.invalidate(conversationsProvider);
    },
  )
  ..subscribe();
```

> **Note:** Also subscribe with `user_two_id=eq.<userId>` filter to catch conversations where current user is the recipient. Use two separate channels or combine logic.

---

## Channel Lifecycle Summary

| Channel | Subscribe When | Unsubscribe When |
|---------|---------------|-----------------|
| `messages:*` | Chat screen opens | Chat screen closes |
| `notifications:*` | User logs in | User logs out |
| `inbox:*` | Inbox screen opens | Inbox screen closes |

---

## Enabling Realtime on Tables (Supabase Dashboard)

In Supabase Dashboard → Database → Replication, enable realtime for:

```
✅ messages        (INSERT, UPDATE)
✅ notifications   (INSERT)
✅ conversations   (UPDATE)
```

Or via SQL:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
```

---

## Security Note

Supabase Realtime respects **Row Level Security (RLS)**. The user will only receive events for rows they are allowed to read per the RLS policies. Ensure these policies are set correctly:

| Table | RLS Policy |
|-------|-----------|
| `messages` | User must be `user_one_id` or `user_two_id` in the parent `conversations` row |
| `notifications` | User must be the `user_id` (recipient) |
| `conversations` | User must be `user_one_id` or `user_two_id` |

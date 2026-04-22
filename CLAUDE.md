# discord-luau

## Active work

### Issue #5 — Gateway RATE_LIMITED event + cache strategy

Two related areas of work identified in conversation. Neither is started yet.

---

### 1. Gateway RATE_LIMITED handling

**Problem:** When Discord sends a `RATE_LIMITED` dispatch event (op 0, `t = "RATE_LIMITED"`) the shard silently drops it. The HTTP layer (`packages/state/src/rest.luau`) has proper rate limit handling via before/after hooks — the gateway should follow the same pattern.

**What to change:**

`packages/api_types/src/gateway/receiveEvents.luau`
- Add `RateLimited = "RATE_LIMITED"` to the `ReceiveEvents` table and the `ReceiveEvent` union type

`packages/websocket/src/shard.luau`
- In the op 0 dispatch handler (around line 665), intercept `payload.t == "RATE_LIMITED"`
- Read `retry_after` and `resource` from the payload `d` field
- Set a `resourcesBlocked` entry (similar to `state/src/rest.luau:implementErrorHandlerFor`) and schedule its removal after `retry_after` seconds
- Log a warning

`packages/websocket/src/shard.luau` — `sendAsync`
- Before writing to the socket, call a `yieldUntil` check against the blocked state (mirrors how `implementGlobalRatelimitsFor` yields before HTTP sends)

**What NOT to do:** No new public API for `requestGuildMembers` is needed to fix this. The rate limit tracking is purely internal plumbing.

**Reference — HTTP rate limit pattern in `packages/state/src/rest.luau`:**
- `implementErrorHandlerFor` — sets `isBlocked`/`resourcesBlocked` on 429, clears after `retry_after`
- `implementGlobalRatelimitsFor` — `yieldUntil` before send checks those flags
- `yieldUntil` — polls a condition every 0.5s, warns after 5s

---

### 2. Cache strategy

**Current state:**
- `packages/state/src/state.luau` has caches for guilds, users, channels, roles (1-hour TTL)
- `packages/state/src/cache.luau` uses a weak table (`__mode = "kv"`) with a coroutine holding strong refs for the TTL duration — expiry is soft/GC-dependent, not guaranteed
- Gateway CREATE/UPDATE events write to cache (e.g. `ChannelCreate` sets `state.cache.channels`)
- Gateway DELETE events do NOT remove from cache — there is no `remove` method on `Cache`
- `getXxxAsync` methods on Guild go straight to HTTP, never check cache

**Plan:**

`packages/state/src/cache.luau`
- Add a `remove(key)` method
- Remove the TTL/expiry mechanism entirely — explicit invalidation via gateway events is the right model, TTL is the wrong one here

`packages/discord_luau/src/bot.luau` — gateway dispatch handler
- DELETE events (ChannelDelete, GuildDelete, etc.) should call `cache:remove(id)`
- Already writing on CREATE/UPDATE, just need the DELETE side

`packages/classes/src/guild/guild.luau` (and equivalent classes)
- `getChannelAsync`, `getMemberAsync`, etc.: check cache first, fall back to HTTP on miss, write HTTP result into cache

**Scope boundary:** Members and users stay HTTP-only for now. They are not reliably covered by gateway events without the privileged `GUILD_MEMBERS` intent. Cache-first only applies to guilds, channels, and roles.

**Key insight:** If gateway events are handled correctly (write on CREATE/UPDATE, evict on DELETE), a cache hit is fully trustworthy — no TTL needed as a safety net. The TTL was compensating for missing DELETE invalidation.

---

## Architecture notes

- `packages/state/src/rest.luau` — rate limit state, before/after hooks wired onto every HTTP request
- `packages/websocket/src/shard.luau` — single WebSocket connection, op dispatch, `sendAsync`
- `packages/websocket/src/manager.luau` — multi-shard coordinator, `sendAsync` broadcasts to all shards
- `packages/state/src/state.luau` — shared state (token, rest, websocket manager, cache)
- `packages/classes/src/guild/guild.luau` — Guild class with all member/channel/role HTTP methods
- `packages/api_types/src/gateway/receiveEvents.luau` — gateway event name constants

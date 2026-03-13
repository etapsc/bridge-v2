---
name: Mobile Specialization
description: Domain conventions for mobile development — platform lifecycle, offline support, performance, and app store constraints.
---

# Mobile Conventions

Apply these conventions when working on mobile application code within the current slice.

## Platform Lifecycle
- Handle all lifecycle states: foreground, background, suspended, terminated
- Save state before backgrounding — restore seamlessly on resume
- Release resources (camera, GPS, audio) when entering background
- Handle configuration changes (rotation, split-screen) without data loss
- Deep links must resolve correctly regardless of app state (cold start, warm start, foreground)

## Offline-First
- Cache critical data locally — app must show useful content without network
- Queue mutations when offline — sync when connectivity resumes
- Conflict resolution strategy defined before implementation (last-write-wins, merge, manual)
- Show clear UI indicators for offline state and pending sync
- Test the full offline→online→sync cycle, not just happy-path connectivity

## Performance
- Startup time under 2 seconds to first meaningful content on target devices
- Smooth scrolling: 60fps for lists, no frame drops during scroll
- Memory budget: monitor and cap memory usage per screen
- Image loading: thumbnails first, full resolution on demand, memory-mapped for large images
- Background work must not drain battery — use system-scheduled jobs, not timers

## Network & Battery
- Batch network requests where possible — reduce connection overhead
- Respect system low-power mode — reduce background activity
- Use appropriate network quality detection — adjust payload size for slow connections
- Cache API responses with appropriate TTL — minimize redundant fetches
- Download large assets on Wi-Fi only unless user explicitly requests otherwise

## App Store Constraints
- No private API usage — app review will reject it
- Request permissions at point of use with clear explanation — not at launch
- Handle permission denial gracefully — provide degraded experience, not a dead end
- Follow platform UI guidelines for navigation, gestures, and visual design
- Test on minimum supported OS version, not just latest

## Anti-Patterns
- Do NOT block the main/UI thread with synchronous network or database calls
- Do NOT ignore memory warnings — release caches and non-essential resources immediately
- Do NOT store sensitive data in plain text — use platform keychain/keystore
- Do NOT assume constant network connectivity — always handle timeout and unreachable states
- Do NOT use platform-specific code where a shared abstraction exists and is well-tested

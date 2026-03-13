---
name: Frontend Specialization
description: Domain conventions for frontend development — component architecture, rendering, accessibility, performance, and state management.
---

# Frontend Conventions

Apply these conventions when working on frontend code within the current slice.

## Component Architecture
- Prefer composition over inheritance for component hierarchies
- Keep components small and focused — one responsibility per component
- Separate data-fetching from presentation (container/presenter or server/client split)
- Co-locate styles, tests, and types with their component

## Rendering & Hydration
- Avoid hydration mismatches: ensure server and client render identical initial markup
- Use server components for data-fetching and static content where supported
- Defer non-critical client-side JavaScript with lazy loading
- Audit components for unnecessary re-renders — memoize where profiling confirms benefit

## Accessibility Checklist
- All interactive elements must be keyboard-navigable (tab order, enter/space activation)
- Images require meaningful alt text (or alt="" for decorative)
- Form inputs require associated labels (htmlFor/id pairing)
- Color contrast must meet WCAG AA (4.5:1 for text, 3:1 for large text)
- ARIA attributes only when native semantics are insufficient
- Test with screen reader (VoiceOver, NVDA) for critical user flows

## Performance
- Measure Largest Contentful Paint (LCP), Cumulative Layout Shift (CLS), Interaction to Next Paint (INP)
- Avoid layout shifts from dynamically loaded content — reserve space with aspect ratios or skeletons
- Optimize images: use modern formats (WebP/AVIF), serve responsive sizes, lazy-load below-fold
- Bundle analysis: flag dependencies > 50KB gzipped — consider alternatives or code-splitting
- Avoid blocking the main thread with synchronous operations

## State Management
- Local state for UI-only concerns (form inputs, toggles, modals)
- Shared state only when multiple components need the same data
- Server state (API data) managed through data-fetching libraries, not global stores
- URL state for anything that should survive refresh or be shareable

## Anti-Patterns
- Do NOT use `dangerouslySetInnerHTML` or equivalent without sanitization
- Do NOT suppress linter warnings for hooks rules — fix the dependency array
- Do NOT render large lists without virtualization
- Do NOT store derived data in state — compute it
- Do NOT ignore loading and error states in async operations

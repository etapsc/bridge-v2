---
name: Backend Specialization
description: Domain conventions for backend development — API design, database access, error handling, auth, and observability.
---

# Backend Conventions

Apply these conventions when working on backend code within the current slice.

## API Design
- Use consistent resource naming: plural nouns for collections, singular for items
- Return appropriate HTTP status codes: 201 for creation, 204 for deletion, 409 for conflicts
- Paginate list endpoints by default — never return unbounded collections
- Version APIs when breaking changes are unavoidable
- Document request/response schemas — keep API docs in sync with code

## Database Access
- Always use parameterized queries — never interpolate user input into SQL
- Watch for N+1 queries: use eager loading or batch fetching for related data
- Add database indexes for columns used in WHERE, JOIN, and ORDER BY clauses
- Run migrations in transactions where supported — ensure rollback safety
- Use connection pooling — never open a connection per request

## Error Handling
- Return structured error responses with consistent shape (code, message, details)
- Log errors with context (request ID, user ID, operation) but never log credentials or PII
- Distinguish client errors (4xx) from server errors (5xx) — don't expose internal details in 4xx
- Use circuit breakers for external service calls — fail fast when downstream is unhealthy
- Retry with exponential backoff for transient failures only

## Authentication & Authorization
- Validate tokens on every request — never trust client-side claims alone
- Use short-lived access tokens with refresh token rotation
- Apply authorization checks at the service layer, not just the route layer
- Rate-limit authentication endpoints to prevent credential stuffing
- Never log tokens, passwords, or session identifiers

## Observability
- Structured logging with consistent fields (timestamp, level, request_id, duration_ms)
- Emit latency histograms for all endpoint handlers
- Trace cross-service calls with propagated correlation IDs
- Alert on error rate spikes and latency percentile degradation, not just averages
- Health check endpoint that validates downstream dependencies

## Anti-Patterns
- Do NOT use ORM lazy loading in request handlers — it causes N+1 queries under load
- Do NOT catch and swallow exceptions silently — at minimum log with context
- Do NOT store sessions or cache in the application process — use external stores
- Do NOT use synchronous calls for operations that can be async (email, notifications, analytics)
- Do NOT hardcode timeouts — make them configurable per external dependency

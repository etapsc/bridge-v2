---
name: API Specialization
description: Domain conventions for API design — contracts, versioning, pagination, rate limiting, and documentation.
---

# API Conventions

Apply these conventions when designing or modifying API contracts within the current slice.

## Contract Design
- Define request and response schemas before implementation — contract-first development
- Use consistent envelope format: `{ "data": ..., "meta": ..., "errors": ... }`
- Require explicit content-type headers — reject requests with wrong content type
- Validate all inputs at the boundary — use schema validation (JSON Schema, Zod, Pydantic)
- Treat the API contract as a public interface — breaking changes require versioning

## Versioning
- Prefer URL path versioning (/v1/, /v2/) for simplicity and cacheability
- Never remove or rename fields in the current version — add new fields, deprecate old ones
- Document deprecation timeline when introducing a new version
- Run both versions in parallel during migration period

## Pagination
- Default page size with configurable limit (e.g., `?limit=20&offset=0` or cursor-based)
- Return total count or next cursor in response metadata
- Cap maximum page size to prevent abuse (e.g., max 100)
- Cursor-based pagination for real-time data or large datasets

## Rate Limiting
- Apply rate limits per API key or user, not per IP alone
- Return `429 Too Many Requests` with `Retry-After` header
- Document rate limit tiers in API docs
- Use sliding window or token bucket — not fixed window (avoids burst at window boundaries)

## Error Responses
- Consistent error shape: `{ "error": { "code": "VALIDATION_ERROR", "message": "...", "details": [...] } }`
- Use machine-readable error codes, not just HTTP status codes
- Include field-level validation errors in details array
- Never expose stack traces, SQL errors, or internal paths in production error responses

## Documentation
- Every endpoint: method, path, request schema, response schema, error codes, example
- Keep examples current — outdated examples are worse than no examples
- Document authentication requirements per endpoint
- Include rate limit information in endpoint documentation

## Anti-Patterns
- Do NOT return 200 with an error body — use proper HTTP status codes
- Do NOT use query parameters for sensitive data (tokens, passwords) — they appear in logs
- Do NOT design RPC-style endpoints on a REST API — use resources and standard methods
- Do NOT accept unbounded arrays in request bodies without size limits
- Do NOT ignore CORS configuration — misconfigured CORS is a security risk

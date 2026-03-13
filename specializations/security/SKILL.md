---
name: Security Specialization
description: Domain conventions for security — threat modeling, input validation, dependency auditing, and secure defaults.
---

# Security Conventions

Apply these conventions when working on any code within the current slice. Security is not a separate concern — it is embedded in every decision.

## Threat Modeling
- Identify trust boundaries for the current slice: where does untrusted input enter?
- Consider the STRIDE categories: Spoofing, Tampering, Repudiation, Information Disclosure, DoS, Elevation of Privilege
- Document assumptions about the threat model in the slice notes
- Prioritize mitigations by impact and likelihood — not everything needs fixing immediately

## Input Validation
- Validate ALL input at system boundaries: HTTP requests, file uploads, webhooks, CLI args
- Use allow-lists over deny-lists — define what IS valid, reject everything else
- Validate type, length, range, and format — not just presence
- Reject input that fails validation with clear error messages (but no internal details)
- Double-encode prevention: validate after URL/HTML/JSON decoding

## Output Encoding
- HTML-encode all dynamic content rendered in web pages — prevent XSS
- Use parameterized queries for ALL database access — prevent SQL injection
- Escape shell metacharacters when constructing commands — or avoid shell invocation entirely
- Set Content-Type headers explicitly — prevent MIME sniffing attacks
- Use Content-Security-Policy headers to limit script sources

## Dependency Security
- Audit dependencies for known vulnerabilities before adding and on every build
- Pin dependency versions — avoid pulling in unreviewed changes via ranges
- Prefer well-maintained dependencies with active security response
- Review transitive dependencies — your direct dependency's vulnerability is your vulnerability
- Remove unused dependencies — reduce attack surface

## Secrets & Credentials
- Never in source code, config files, logs, error messages, or URLs
- Use environment variables or secret managers — rotate on a schedule
- Encrypt at rest and in transit — TLS 1.2+ for all network communication
- Use short-lived credentials where possible (temporary tokens, service accounts)
- Audit access to secrets — log retrieval events

## Secure Defaults
- Default to deny — require explicit permission grants
- Default to encrypted — require explicit opt-out for unencrypted channels
- Default to authenticated — anonymous access only when intentional
- Default to logged — security-relevant events always recorded
- Default to minimal privilege — request only needed permissions

## Anti-Patterns
- Do NOT disable SSL verification, even in tests — use proper test certificates
- Do NOT use MD5 or SHA1 for security purposes — use SHA-256+ or bcrypt/argon2 for passwords
- Do NOT roll your own crypto — use established libraries
- Do NOT trust client-side validation alone — always re-validate server-side
- Do NOT expose detailed error messages in production — log internally, return generic messages

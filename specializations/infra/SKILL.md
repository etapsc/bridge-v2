---
name: Infrastructure Specialization
description: Domain conventions for infrastructure — IaC, deployment, secret management, observability, and reliability.
---

# Infrastructure Conventions

Apply these conventions when working on infrastructure code within the current slice.

## Infrastructure as Code
- All infrastructure defined in version-controlled code — no manual console changes
- Use modules/components for reusable patterns (VPC, database, service)
- Tag all resources with: project, environment, owner, cost-center
- Plan before apply — review diff before any infrastructure change
- State files stored remotely with locking (never local, never committed)

## Deployment Safety
- Blue-green or canary deployments for production services — never big-bang
- Rollback plan documented for every deployment — "how to undo" before "how to do"
- Health checks gate traffic shift — unhealthy instances never receive traffic
- Database migrations run before code deployment — backward-compatible schema changes only
- Feature flags for risky changes — deploy dark, enable incrementally

## Secret Management
- Secrets in a secrets manager (Vault, AWS SM, GCP SM) — never in env files or code
- Rotate secrets on a schedule — automate rotation where possible
- Least-privilege access: services get only the secrets they need
- Audit secret access — log who accessed what and when
- Separate secrets per environment — never share production credentials with staging

## Observability
- Three pillars: structured logs, metrics, distributed traces
- Alert on symptoms (error rate, latency), not causes (CPU, memory) — unless capacity planning
- Dashboard per service: request rate, error rate, latency percentiles, saturation
- Log retention policy: 30 days hot, 90 days warm, archive beyond that
- Runbook linked from every alert — "what to do when this fires"

## Reliability
- Define SLOs for critical paths — measure against them weekly
- Circuit breakers for all external dependencies
- Graceful degradation: identify what can be disabled without total outage
- Load test before launch and after major changes — know your capacity limits
- Incident response: severity definitions, escalation paths, postmortem template

## Anti-Patterns
- Do NOT hardcode IP addresses, ports, or hostnames — use DNS and service discovery
- Do NOT grant admin/root access to service accounts — principle of least privilege
- Do NOT skip TLS for internal service communication — zero-trust networking
- Do NOT use latest/mutable tags for container images — pin specific versions
- Do NOT ignore resource limits — set CPU/memory requests and limits for all workloads

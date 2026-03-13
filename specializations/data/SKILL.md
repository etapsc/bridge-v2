---
name: Data Specialization
description: Domain conventions for data engineering — schema design, migrations, query optimization, and data pipelines.
---

# Data Conventions

Apply these conventions when working on data models, schemas, or pipelines within the current slice.

## Schema Design
- Normalize to 3NF by default — denormalize only with measured read performance justification
- Use consistent naming: snake_case for columns, plural for tables, singular for models
- Every table gets a primary key, created_at, and updated_at
- Use UUIDs for public-facing IDs, auto-increment for internal foreign keys
- Add NOT NULL constraints by default — allow NULL only when absence is semantically meaningful

## Migrations
- Every schema change gets a versioned, reversible migration file
- Test migrations against a copy of production-scale data before deploying
- Never modify a deployed migration — create a new one
- Large table alterations (adding columns, indexes) must be non-blocking where possible
- Data backfills go in separate migrations from schema changes

## Query Optimization
- EXPLAIN every query that touches tables with > 10K rows
- Index columns used in WHERE, JOIN ON, and ORDER BY — check composite index order
- Avoid SELECT * — specify needed columns explicitly
- Watch for sequential scans on large tables — they indicate missing indexes
- Use query result caching for expensive aggregations with known staleness tolerance

## Data Integrity
- Use foreign key constraints for referential integrity
- Apply check constraints for domain invariants (positive amounts, valid status values)
- Use transactions for multi-table operations — ensure atomicity
- Implement soft-delete (deleted_at) for audit-critical data
- Validate data at the application layer AND the database layer

## Pipelines
- Idempotent processing: re-running a pipeline step produces the same result
- Track pipeline state: which records processed, last checkpoint, failure point
- Validate input data shape before processing — fail fast on unexpected schemas
- Log record counts at each pipeline stage for reconciliation
- Separate extraction, transformation, and loading concerns

## Anti-Patterns
- Do NOT store monetary values as floating point — use decimal/numeric types
- Do NOT use EAV (Entity-Attribute-Value) patterns — they defeat query optimization
- Do NOT delete data without archiving in regulated environments
- Do NOT create indexes speculatively — profile first, index second
- Do NOT mix DDL and DML in the same transaction on databases that don't support it

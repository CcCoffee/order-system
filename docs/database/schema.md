# Database Schema

## orders

| Column | Type | Description |
|---|---|---|
| id | UUID | Order identifier |
| user_id | UUID | Owner |
| status | VARCHAR | Order status |
| total_amount | DECIMAL | Total amount |
| created_at | TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | Last update |

## Migration Policy

All changes require Flyway migrations.

Never modify production schema manually.

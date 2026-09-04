# Database

PostgreSQL is the source of truth for persistent business data.

All schema changes must use Flyway migrations (see
`backend/order-service/src/main/resources/db/migration`).

Never manually modify production schema.

---

## Schema

### products

| column     | type          | notes                |
| ---------- | ------------- | -------------------- |
| id         | UUID          | primary key          |
| name       | VARCHAR(255)  | product name         |
| price      | NUMERIC(12,2) | unit price           |
| created_at | TIMESTAMP     | creation timestamp   |

### inventory

| column            | type        | notes                                  |
| ----------------- | ----------- | -------------------------------------- |
| id                | UUID        | primary key                            |
| product_id        | UUID        | unique, references products(id)        |
| quantity          | INT         | units available to sell                |
| reserved_quantity | INT         | units held by pending orders           |
| version           | BIGINT      | optimistic lock for concurrent updates |

### orders

| column       | type          | notes                        |
| ------------ | ------------- | ---------------------------- |
| id           | UUID          | primary key                  |
| status       | VARCHAR(20)   | PENDING/PAID/SHIPPED/...     |
| total_amount | NUMERIC(12,2) | order total                  |
| created_at   | TIMESTAMP     | creation timestamp           |
| updated_at   | TIMESTAMP     | last change timestamp        |
| version      | BIGINT        | optimistic lock              |

### order_items

| column       | type          | notes                   |
| ------------ | ------------- | ----------------------- |
| id           | UUID          | primary key             |
| order_id     | UUID          | references orders(id)   |
| product_id   | UUID          | product reference       |
| product_name | VARCHAR(255)  | product name snapshot   |
| unit_price   | NUMERIC(12,2) | price at time of order  |
| quantity     | INT           | ordered quantity        |
| line_total   | NUMERIC(12,2) | unit price * quantity   |

### audit_logs

| column        | type        | notes                        |
| ------------- | ----------- | ---------------------------- |
| id            | UUID        | primary key                  |
| order_id      | UUID        | referenced order             |
| event         | VARCHAR(50) | e.g. ORDER_CREATED           |
| status_before | VARCHAR(20) | previous status (nullable)   |
| status_after  | VARCHAR(20) | new status                   |
| created_at    | TIMESTAMP   | audit timestamp              |

---

## Redis

Redis has two meaningful production uses in the Order Service:

### 1. Short-lived order-response cache

Order responses are cached under `orders:{orderId}` with a 5-minute TTL to
reduce database load on frequent order lookups. The cache is evicted whenever
an order's state changes (e.g. cancellation) so stale data is never served.

### 2. Idempotency store for order creation

A client-supplied `Idempotency-Key` header is mapped to the created order id
under `idempotency:{key}` with a 24-hour TTL. Retried create requests return
the original order instead of creating a duplicate, which prevents double
orders from retries or timeouts.

Redis is not used merely because the stack includes it; it solves real
consistency and performance concerns as described above.

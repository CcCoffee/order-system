CREATE TABLE products (
    id          UUID PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    price       NUMERIC(12, 2) NOT NULL,
    created_at  TIMESTAMP NOT NULL
);

CREATE TABLE inventory (
    id                UUID PRIMARY KEY,
    product_id        UUID NOT NULL UNIQUE REFERENCES products(id),
    quantity          INT NOT NULL,
    reserved_quantity INT NOT NULL DEFAULT 0,
    version           BIGINT NOT NULL DEFAULT 0
);

CREATE TABLE orders (
    id           UUID PRIMARY KEY,
    status       VARCHAR(20) NOT NULL,
    total_amount NUMERIC(12, 2) NOT NULL,
    created_at   TIMESTAMP NOT NULL,
    updated_at   TIMESTAMP NOT NULL,
    version      BIGINT NOT NULL DEFAULT 0
);

CREATE TABLE order_items (
    id           UUID PRIMARY KEY,
    order_id     UUID NOT NULL REFERENCES orders(id),
    product_id   UUID NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    unit_price   NUMERIC(12, 2) NOT NULL,
    quantity     INT NOT NULL,
    line_total   NUMERIC(12, 2) NOT NULL
);

CREATE TABLE audit_logs (
    id            UUID PRIMARY KEY,
    order_id      UUID NOT NULL,
    event         VARCHAR(50) NOT NULL,
    status_before VARCHAR(20),
    status_after  VARCHAR(20),
    created_at    TIMESTAMP NOT NULL
);

CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_audit_logs_order_id ON audit_logs(order_id);
CREATE INDEX idx_inventory_product_id ON inventory(product_id);

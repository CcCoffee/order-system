INSERT INTO products (id, name, price, created_at) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Widget', 10.00, now()),
    ('22222222-2222-2222-2222-222222222222', 'Gadget', 25.50, now()),
    ('33333333-3333-3333-3333-333333333333', 'Gizmo', 5.75, now());

INSERT INTO inventory (id, product_id, quantity, reserved_quantity, version) VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 100, 0, 0),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 50, 0, 0),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', '33333333-3333-3333-3333-333333333333', 200, 0, 0);

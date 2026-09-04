# Order UI Rules

This directory contains order-related UI.

Order status must come from the backend API contract.

Do not duplicate order state transition rules in the frontend.

The frontend may control presentation, but the backend is authoritative for business rules.

Order cancellation UI must:

- show only when cancellation is allowed by the current API state
- handle loading state
- handle success
- handle 409 conflict
- handle network failure
- refresh/invalidate order data after cancellation

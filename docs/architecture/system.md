# Order System Architecture

## Logical Architecture

React Frontend
    ↓
API Gateway
    ↓
Order Service
    ├── PostgreSQL
    ├── Redis
    └── Event Bus

## Core Domain

The system manages:

- Users
- Products
- Orders
- Payments

## Order Lifecycle

PENDING
    ↓
PAID
    ↓
SHIPPED
    ↓
COMPLETED

Cancellation is allowed only for states explicitly defined by the business rules.


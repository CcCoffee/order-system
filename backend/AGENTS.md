# Backend Engineering Rules

This directory contains Spring Boot backend services.

---

# Architecture

Use:

Controller
 ↓
Application Service
 ↓
Domain
 ↓
Infrastructure

Controllers must not directly access repositories.

---

# API

Controllers are responsible for:

- HTTP concerns
- request validation
- response mapping

Business logic belongs in application/domain layers.

Use explicit request/response DTOs.

Do not expose persistence entities directly.

---

# Application

Application services coordinate use cases.

Transactions should normally be defined at application-service boundaries.

---

# Domain

Domain code contains business rules and state transitions.

Avoid placing business rules inside:

- controllers
- repositories
- DTOs

---

# Infrastructure

Infrastructure contains:

- PostgreSQL
- Redis
- external APIs
- messaging
- persistence implementations

---

# Database

Use Flyway migrations.

Never modify production schema manually.

---

# Redis

Redis is used for:

- caching
- short-lived state

Cache invalidation must be considered whenever mutable domain state changes.

---

# Testing

Business logic requires unit tests.

Database behavior requires integration tests.

Public APIs require integration/API tests.

---

# Verification

Run:

    ./scripts/verify-backend.sh

# Backend Architecture

Controller
    |
Application Service
    |
Domain
    |
Infrastructure

Controllers do not access repositories directly.

Transactions normally belong at application-service boundaries.

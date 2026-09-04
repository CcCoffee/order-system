# Order System Architecture

React Frontend
      |
      v
API Gateway
      |
      v
Order Service
   |       |
   v       v
PostgreSQL Redis

Order Service owns the Order domain.

OpenAPI defines external API contracts.

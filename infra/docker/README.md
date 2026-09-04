# Local Infrastructure

The local development environment uses Docker Compose.

## PostgreSQL

```text
host: localhost
port: 5434
database: order_system
username: postgres
password: 123456
```

## Redis

```text
host: localhost
port: 6380
```

## Startup

Start the infrastructure:

```bash
./scripts/start-infra.sh
```

Stop the infrastructure:

```bash
./scripts/stop-infra.sh
```

Reset and recreate the infrastructure:

```bash
./scripts/reset-infra.sh
```

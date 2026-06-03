# power-dns-server

A minimal Docker image running PowerDNS Authoritative Server with a SQLite3 backend. Built as a self-contained component for larger deployments — no CLI tools, no interactive shell.

## Quick Start

```bash
# Build locally
docker build -t power-dns-server .

# Run
docker run -d --name powerdns \
  -p 53:53/tcp -p 53:53/udp \
  -p 8080:80/tcp \
  -v powerdns-data:/var/lib/powerdns \
  power-dns-server
```

On first start, `init.sh` creates the SQLite database at `/var/lib/powerdns/pdns.db` with the required schema. On subsequent starts, the existing database is used as-is. The container then launches `pdns_server` in the foreground.

## Default Settings

| Setting           | Value                        |
|-------------------|------------------------------|
| DNS port          | 53 (UDP + TCP)               |
| API port          | 80                           |
| API key           | `secret`                     |
| Backend           | `gsqlite3` (SQLite3)         |
| Database path     | `/var/lib/powerdns/pdns.db`  |
| Listen address    | `0.0.0.0`                    |
| API access        | `0.0.0.0/0,::/0` (all)       |

## API Access

The PowerDNS HTTP API is enabled by default. Authenticate with the `X-API-Key` header.

```bash
# List all domains
curl -s http://localhost:8080/api/v1/servers/localhost/zones \
  -H "X-API-Key: secret" | jq .

# Create a zone
curl -s -X POST http://localhost:8080/api/v1/servers/localhost/zones \
  -H "X-API-Key: secret" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "example.com.",
    "kind": "Native",
    "zone": "$ORIGIN example.com.\n$TTL 3600\n@ SOA ns1 admin 2024060101 3600 900 604800 86400"
  }' | jq .

# List records for a zone
curl -s http://localhost:8080/api/v1/servers/localhost/zones/example.com. \
  -H "X-API-Key: secret" | jq .

# Update a zone (replace all records)
curl -s -X PUT http://localhost:8080/api/v1/servers/localhost/zones/example.com. \
  -H "X-API-Key: secret" \
  -H "Content-Type: application/json" \
  -d @zone.json
```

For the full API specification, see the [PowerDNS HTTP API documentation](https://doc.powerdns.com/authoritative/httpapi/index.html).

## Persistence

The SQLite database lives at `/var/lib/powerdns/pdns.db`. Without a volume, all data is lost when the container is removed.

```bash
# Named volume (recommended)
docker run -d --name powerdns \
  -v powerdns-data:/var/lib/powerdns \
  power-dns-server

# Bind mount
docker run -d --name powerdns \
  -v ./data:/var/lib/powerdns \
  power-dns-server
```

## Configuration

The bundled `pdns.conf` covers the common defaults. To override settings, mount a custom config:

```bash
docker run -d --name powerdns \
  -v ./my-pdns.conf:/etc/pdns/pdns.conf \
  power-dns-server
```

Key configuration options:

| Option                  | Default                        | Description                        |
|-------------------------|--------------------------------|------------------------------------|
| `api-key`               | `secret`                       | API authentication key             |
| `webserver-port`        | `80`                           | API/HTTP port                      |
| `webserver-allow-from`  | `0.0.0.0/0,::/0`              | CIDR ranges allowed to reach API   |
| `local-port`            | `53`                           | DNS response port                  |
| `gsqlite3-database`     | `/var/lib/powerdns/pdns.db`    | SQLite database file path          |
| `loglevel`              | `4`                            | 0–9, higher is more verbose        |
| `default-ttl`           | `600`                          | Default TTL for records (seconds)  |

## Docker Image

| Property      | Detail                                |
|---------------|---------------------------------------|
| Base image    | `alpine:3.21`                         |
| Build         | Single-stage, no build tools retained  |
| Size target   | ~30 MB                                |
| CI            | GitHub Actions — pushes to `ghcr.io`  |
| Tags          | `latest` (main branch), git SHA       |

Pull the pre-built image:

```bash
docker pull ghcr.io/<owner>/power-dns-server:latest
```

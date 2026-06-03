# Спецификация задачи 004: Написать README.md

## Описание

Заменить текущий README.md (2 строки) на полную документацию Docker-образа.

## Полный контекст

Текущий `README.md`:
```
# power-dns-server
PowerDNS server (sqlite3)
```

Нужно написать документацию, которая покрывает:
1. Что это за образ
2. Как запустить (быстрый старт)
3. Настройки по умолчанию
4. Переменные окружения
5. Доступ к API
6. Сохранение данных

## Технические детали

### Структура README.md

```markdown
# power-dns-server

Clean, lightweight Docker image of PowerDNS Authoritative Server with SQLite3 backend.
Managed via REST API. Designed as a component for larger projects with external Admin UI.

## Quick Start

```bash
# Build
docker build -t powerdns-server .

# Run
docker run -d --name pdns -p 53:53/udp -p 53:53/tcp -p 8080:80 powerdns-server
```

## Default Settings

| Setting        | Value           |
|---------------|-----------------|
| API Key        | `secret`        |
| DNS Port       | `53` (UDP+TCP)  |
| API Port       | `80`            |
| API Allow From | `0.0.0.0/0`     |
| Database       | SQLite3 (`/var/lib/powerdns/pdns.db`) |

## API Access

PowerDNS REST API v1 is enabled by default.

```bash
# Test API connectivity
curl -H "X-API-Key: secret" http://localhost:8080/api/v1/servers/localhost

# List zones
curl -H "X-API-Key: secret" http://localhost:8080/api/v1/servers/localhost/zones
```

## Persistence

Mount a volume to persist the SQLite database:

```bash
docker run -d --name pdns \
  -p 53:53/udp -p 53:53/tcp -p 8080:80 \
  -v pdns-data:/var/lib/powerdns \
  powerdns-server
```

## Configuration

Override defaults by mounting a custom `pdns.conf`:

```bash
docker run -d --name pdns \
  -p 53:53/udp -p 53:53/tcp -p 8080:80 \
  -v $(pwd)/pdns.conf:/etc/pdns/pdns.conf:ro \
  powerdns-server
```

## License

MIT
```

### Что обязательно включить

- Описание образа (первый абзац)
- Quick Start с docker build + docker run
- Таблица Default Settings (API key, ports, backend)
- API Access с curl примерами
- Persistence с volume примером
- Configuration с mount custom config

### Язык

Английский (стандарт для Docker Hub / GHCR образов).

## Файлы для изменения

| Файл | Действие |
|------|----------|
| `README.md` | Rewrite — полная замена |

## Требования к юнит-тестам

Нет (документация проверяется визуально и через Group C integration test).

## Критерии приёмки

- [ ] README.md содержит секцию Quick Start с командами build + run
- [ ] README.md содержит таблицу Default Settings с api-key=secret
- [ ] README.md содержит секцию API Access с curl примерами
- [ ] README.md содержит секцию Persistence с volume примером
- [ ] README.md содержит секцию Configuration
- [ ] Нет упоминания CLI-скриптов (они вне scope)
- [ ] Markdown валиден, нет битых ссылок

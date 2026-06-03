# Спецификация: power-dns-server

## 1. Цель

Создать легковесный, быстрый Docker-образ PowerDNS Authoritative Server, управляемый через CLI-скрипты, взаимодействующие с REST API. Проект должен позволить разработчикам программно управлять зонами и DNS-записями без необходимости открывать веб-интерфейс.

**Ожидаемый результат:** готовый образ и набор скриптов, позволяющих выполнять полный жизненный цикл DNS-зон (создание, редактирование, удаление) через CLI.

---

## 2. Текущее состояние (As-Is)

| Элемент | Описание | Проблемы |
|---------|----------|----------|
| `Dockerfile` | Alpine 3.21, pdns + backend-sqlite3 + sqlite CLI | Нет оптимизации размера, sqlite CLI в рантайме (нужна проверка) |
| `pdns.conf` | API включён, sqlite3 backend, порт 80 | Жёстко заданный API-ключ `changeme`, `webserver-allow-from=0.0.0.0/0` |
| `init.sh` | DB init + запуск pdns_server | Работает корректно |
| Скрипты управления | Отсутствуют | **Ключевой пробел** |
| `compose.yaml` | Отсутствует | **Ключевой пробел** |
| Документация | README — 1 строка | Недостаточно |

---

## 2.1. Фаза 1: Clean Docker Image (текущий итерация)

В рамках текущей итерации фокус — **чистый Docker-образ без скриптов**.
Изменения относительно §3.3 и §8.4:

| Требование | spec.md (глобально) | Фаза 1 (текущая) | Причина |
|-----------|---------------------|-------------------|---------|
| API-ключ | `PDNS_API_KEY` env var | `api-key=secret` в конфиге | Упрощение — образ как компонент, ключ задаётся в pdns.conf |
| webserver-allow-from | `127.0.0.1/8,::1/128` | `0.0.0.0/0,::/0` | Компонент запускается внутри внутренней сети |
| Скрипты CLI | В scope | Вне scope (фаза 2+) | Сначала чистый образ |

Полный план задач см. `plan.md`.

---

## 3. Функциональные требования

### 3.1. Скрипты управления (CLI)

Скрипты должны обеспечивать CRUD-операции для зон и DNS-записей через PowerDNS REST API.

#### Поддерживаемые команды

| Команда | Описание | API endpoint |
|---------|----------|--------------|
| `zone-create` | Создать новую зону | `POST /api/v1/servers/localhost/zones` |
| `zone-list` | Список всех зон | `GET /api/v1/servers/localhost/zones` |
| `zone-get` | Получить детали зоны | `GET /api/v1/servers/localhost/zones/{zone}` |
| `zone-delete` | Удалить зону | `DELETE /api/v1/servers/localhost/zones/{zone}` |
| `record-create` | Добавить запись в зону | `POST /api/v1/servers/localhost/zones/{zone}/records` |
| `record-list` | Список записей зоны | `GET /api/v1/servers/localhost/zones/{zone}/records` |
| `record-update` | Обновить запись | `PATCH /api/v1/servers/localhost/zones/{zone}/records/{name}/{type}` |
| `record-delete` | Удалить запись | `DELETE /api/v1/servers/localhost/zones/{zone}/records/{name}/{type}` |

#### Пример использования

```bash
# Создать зону
./scripts/pdns.sh zone-create example.com --type authoritative --nameservers ns1.example.com

# Добавить A-запись
./scripts/pdns.sh record-create example.com --name www --type A --content 192.168.1.1 --ttl 300

# Добавить запись с приоритетом (MX)
./scripts/pdns.sh record-create example.com --name @ --type MX --content "10 mail.example.com" --prio 10

# Список записей
./scripts/pdns.sh record-list example.com

# Удалить зону
./scripts/pdns.sh zone-delete example.com
```

#### Интерфейс CLI

- **Язык реализации:** Bash с использованием `curl` (лёгкая зависимость, нет доп. рантаймов)
- **Единый вход:** один скрипт `scripts/pdns.sh` с подкомандами
- **Конфигурация:**
  - Переменные окружения: `PDNS_API_HOST`, `PDNS_API_PORT`, `PDNS_API_KEY`
  - Опционально: файл `.pdns_env` в текущей директории с парами `ключ=значение`
- **Валидация:** проверка обязательных параметров до отправки запроса
- **Вывод:**
  - Success: human-readable сообщение
  - Error: текст ошибки + HTTP status code
  - `--json` флаг для получения сырого JSON-ответа API (для пайплайнов)

### 3.2. Docker-образ

| Требование | Текущее | Целевое |
|------------|---------|---------|
| Базовый образ | `alpine:3.21` | `alpine:3.21` (оставить) |
| Размер образа | ~40 MB (оценка) | ≤ 30 MB |
| Модель сборки | single-stage | single-stage (Alpine достаточно лёгкий, multi-stage не добавляет ценности) |
| Пользователь | `pdns:pdns` | Сохранить |

#### Оптимизации образа

1. **sqlite CLI** — оставить в образе (требуется `init.sh` для инициализации БД при первом запуске)
2. **`--no-cache` уже используется** — оставить
3. **Минимизация слоёв** — объединить `apk add` в одну команду (сейчас 2 отдельных `RUN apk add`)
4. **Добавить `.dockerignore`** — исключить `.git/`, `*.md`, `devdocs/`, etc.

### 3.3. Безопасность

| Требование | Текущее | Целевое (глобально) | Фаза 1 (текущая) |
|------------|---------|---------------------|-------------------|
| API-ключ | Жёстко `changeme` | Через переменную окружения `PDNS_API_KEY` | `api-key=secret` в `pdns.conf` |
| webserver-allow-from | `0.0.0.0/0,::/0` | Настраиваемый через env `PDNS_WEBSERVER_ALLOW_FROM` | `0.0.0.0/0,::/0` (внутренняя сеть) |
| TLS для API | Нет | Опционально через обратный прокси (nginx/caddy) вне scope | Вне scope |

#### Меры безопасности

1. **API-ключ:** фаза 1 — `api-key=secret` в `pdns.conf`; глобально — `PDNS_API_KEY` env var
2. **webserver-allow-from:** фаза 1 — `0.0.0.0/0,::/0`; глобально — настраиваемый через env
3. **Permissions:** pdns run от non-root `pdns` пользователя (сохраняется в обеих фазах)

### 3.4. compose.yaml

Создать `compose.yaml` для локального запуска:

```yaml
services:
  pdns:
    build: .
    ports:
      - "53:53/udp"
      - "53:53/tcp"
    environment:
      - PDNS_API_KEY=${PDNS_API_KEY:-changeme}
    volumes:
      - pdns-data:/var/lib/powerdns
    restart: unless-stopped

volumes:
  pdns-data:
```

---

## 4. Нефункциональные требования

### 4.1. Размер образа

Метрика: `docker image ls` — размер image-слоёв (без учёта данных контейнера).

| Метрика | Лимит |
|---------|-------|
| Размер image-слоёв | ≤ 30 MB |

### 4.2. Производительность

Все тайминги измеряются в нормальном сценарии (здоровый API, без сетевых сбоев и retry).

| Метрика | Лимит |
|---------|-------|
| Запуск сервиса | ≤ 2 секунды |
| Время отклика API (localhost) | ≤ 100 ms |
| Время выполнения `zone-create` (скрипт → API → ответ) | ≤ 500 ms |

### 4.3. Надёжность

- Скрипт должен обрабатывать недоступность API (когда `pdns_server` ещё не стартовал) с повторными попытками (retry)
- `init.sh` не должен падать, если БД уже создана (idempotent)

### 4.4. Совместимость

- PowerDNS Authoritative Server ≥ 4.8.x
- SQLite ≥ 3.36
- curl ≥ 7.79
- Docker ≥ 20.10
- Docker Compose ≥ 2.0

---

## 5. Стек технологий

| Компонент | Технология | Версия |
|-----------|-----------|--------|
| Базовый образ | Alpine Linux | 3.21 |
| DNS-сервер | PowerDNS Authoritative Server | ≥ 4.8.x |
| Бэкенд | SQLite (gsqlite3) | ≥ 3.36 |
| Скрипты | Bash (sh) | Alpine default |
| HTTP-клиент в скриптах | curl | ≥ 7.79 |
| Среда выполнения | Docker | ≥ 20.10 |
| Оркестрация | Docker Compose | ≥ 2.0 |

---

## 6. Предлагаемая структура проекта

```
power-dns-server/
├── Dockerfile              # Оптимизированный образ
├── compose.yaml            # Docker Compose для запуска
├── .dockerignore           # Исключения для сборки
├── pdns.conf               # Конфигурация PowerDNS (env-aware)
├── init.sh                 # Инициализация БД (idempotent)
├── scripts/
│   ├── pdns.sh             # Главный CLI-скрипт
│   └── libpdns.sh          # Библиотека общих функций (curl, логирование)
├── devdocs/
│   └── spec.md             # Этот документ
├── README.md               # Расширенная документация
└── LICENSE
```

### Детали структуры

- **`scripts/libpdns.sh`** — вспомогательная библиотека:
  - `_pdns_call()` — универсальная обёртка для HTTP-запросов к API
  - `_pdns_log()` — форматированное логирование
  - `_pdns_error()` — обработка ошибок

- **`scripts/pdns.sh`** — точка входа:
  - Парсинг `subcommand` из `$1`
  - Перенаправление к функциям `cmd_zone_*` и `cmd_record_*`

---

## 7. API-стратегия

PowerDNS REST API v1:

```
Base URL:    http://${PDNS_API_HOST:-localhost}:${PDNS_API_PORT:-80}
Auth header: X-API-Key: ${PDNS_API_KEY}
```

Все запросы идут через единую обёртку `_pdns_call`, которая:

1. Формирует URL
2. Добавляет `X-API-Key`
3. Отправляет запрос с `curl`
4. Проверяет HTTP status
5. Возвращает тело ответа

### Обработка ошибок

| HTTP Status | Действие |
|-------------|----------|
| 200–204 | Success |
| 400 | Вывести ошибку валидации от API |
| 401 | Вывести ошибку аутентификации |
| 404 | Зона/запись не найдена |
| 500 | Ошибка сервера, retry (1 раз) |
| Сеть недоступна | Retry до 3 раз с экспоненциальным backoff |

---

## 8. Критерии приёмки

### 8.1. Образ

- [ ] Образ собирается командой `docker build -t powerdns-server .`
- [ ] Размер image-слоёв ≤ 30 MB (`docker image ls`)
- [ ] В образе отсутствуют ненужные пакеты: `wget`, `vim`, `nano`, `busybox-extras`; присутствуют только `pdns`, `pdns-backend-sqlite3`, `ca-certificates` и необходимые системные зависимости
- [ ] Образ запускается: `docker run --rm powerdns-server`

### 8.2. Композиция

- [ ] `compose.yaml` запускает сервис одной командой: `docker compose up -d`
- [ ] Данные БД сохраняются между перезапусками (volume)
- [ ] API доступен по `localhost:80`

### 8.3. Скрипты

- [ ] `scripts/pdns.sh zone-create` создаёт зону
- [ ] `scripts/pdns.sh zone-list` выводит список зон
- [ ] `scripts/pdns.sh zone-delete` удаляет зону (возвращает HTTP 204)
- [ ] `scripts/pdns.sh record-create` добавляет запись (A, AAAA, MX, CNAME, NS, TXT)
- [ ] `scripts/pdns.sh record-list` выводит записи зоны
- [ ] `scripts/pdns.sh record-update` обновляет запись
- [ ] `scripts/pdns.sh record-delete` удаляет запись
- [ ] Все команды поддерживают `--json` для машинного парсинга
- [ ] `PDNS_API_KEY`, `PDNS_API_HOST` и `PDNS_API_PORT` читаются из окружения
- [ ] Нет жёстко заданного API-ключа в конфигах

### 8.4. Безопасность

- [ ] Фаза 1: `api-key=secret` в `pdns.conf` (не `changeme`)
- [ ] Фаза 1: `webserver-allow-from=0.0.0.0/0,::/0`
- [ ] Глобально: API-ключ через `PDNS_API_KEY` env var (фаза 2+)
- [ ] Глобально: `webserver-allow-from` по умолчанию `127.0.0.1/8` (фаза 2+)
- [ ] Скрипты не логируют API-ключ (фаза 2+)

### 8.5. Документация

- [ ] `README.md` содержит минимум 4 секции: цель, быстрый старт, примеры команд, переменные окружения
- [ ] Документация по переменным окружения в `pdns.conf` / `compose.yaml`

---

## 9. Вне диапазона (Out of Scope)

- Web UI для управления зонами (только CLI)
- TLS/HTTPS для API (за пределами этого проекта, может быть реализовано через nginx/caddy)
- MySQL/PostgreSQL backend (только SQLite3)
- DNSSEC (на данном этапе)
- TSIG keys management (на данном этапе)
- CI/CD пайплайн (в следующих итерациях)
- Multi-tenant / zone delegation (на данном этапе)

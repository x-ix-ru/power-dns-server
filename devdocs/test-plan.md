# План тестирования: Clean PowerDNS Docker Image

## 1. Функциональное тестирование

### 1.1. pdns.conf (Task 001)

| # | Сценарий | Ожидаемый результат |
|---|----------|-------------------|
| 1 | Проверить `api-key` в файле | Значение `secret` |
| 2 | Проверить `webserver-allow-from` | Значение `0.0.0.0/0,::/0` |
| 3 | Проверить `api=yes` | Включён |
| 4 | Проверить `launch=gsqlite3` | Backend SQLite3 |

### 1.2. Dockerfile (Task 002)

| # | Сценарий | Ожидаемый результат |
|---|----------|-------------------|
| 5 | `docker build -t powerdns-server .` | Build завершён успешно |
| 6 | `docker image ls \| grep powerdns-server` | Размер ≤ 30 MB |
| 7 | Проверить содержимое `.dockerignore` | `.git/`, `*.md`, `devdocs/`, `LICENSE` в списке |
| 8 | `docker run --rm powerdns-server ls /` | Нет файлов из `.git/`, `devdocs/` |

### 1.3. init.sh (Task 003)

| # | Сценарий | Ожидаемый результат |
|---|----------|-------------------|
| 9 | Запустить контейнер с чистым volume | БД создана, pdns_server работает |
| 10 | Остановить и перезапустить с тем же volume | Контейнер стартует, БД не переписана |
| 11 | Проверить права на БД | Владелец `pdns:pdns` |

### 1.4. README.md (Task 004)

| # | Сценарий | Ожидаемый результат |
|---|----------|-------------------|
| 12 | Проверить наличие секций | Quick Start, Default Settings, API Access, Persistence, Configuration |
| 13 | Запустить команды из Quick Start | Работают без ошибок |
| 14 | Выполнить curl из API Access | Получён JSON ответ |

---

## 2. Интеграционное тестирование

### Группа A: Build & Start (001 + 002 + 003)

| # | Сценарий | Ожидаемый результат |
|---|----------|-------------------|
| A1 | `docker build -t powerdns-server .` | Сборка OK, размер ≤ 30 MB |
| A2 | `docker run --rm powerdns-server` | Контейнер запускается, в логах «gsqlite3» backend |
| A3 | `docker run --rm powerdns-server cat /etc/pdns/pdns.conf` | `api-key=secret`, `webserver-allow-from=0.0.0.0/0,::/0` |

### Группа B: API & DNS (001 + 002 + 003)

| # | Сценарий | Ожидаемый результат |
|---|----------|-------------------|
| B1 | `docker run -d -p 8080:80 --name pdns-test powerdns-server` | Контейнер запущен |
| B2 | `sleep 2 && curl -s -H "X-API-Key: secret" http://localhost:8080/api/v1/servers/localhost` | HTTP 200, JSON с `"id":"localhost"` |
| B3 | `curl -s -H "X-API-Key: wrong" http://localhost:8080/api/v1/servers/localhost` | HTTP 401 (Unauthorized) |
| B4 | `docker exec pdns-test ls -la /var/lib/powerdns/pdns.db` | Файл существует, владелец `pdns:pdns` |
| B5 | `docker rm -f pdns-test` | Контейнер остановлен и удалён |

### Группа C: Persistence (001 + 002 + 003)

| # | Сценарий | Ожидаемый результат |
|---|----------|-------------------|
| C1 | `docker run -d -v pdns-test-data:/var/lib/powerdns --name pdns-persist powerdns-server` | Старт OK |
| C2 | Создать зону через API | HTTP 20/201 |
| C3 | `docker rm -f pdns-persist` | Остановлен |
| C4 | `docker run -d -v pdns-test-data:/var/lib/powerdns --name pdns-persist2 powerdns-server` | Старт OK |
| C5 | Проверить зону через API | Зона сохранилась |
| C6 | `docker rm -f pdns-persist2 && docker volume rm pdns-test-data` | Cleanup |

### Группа D: Documentation (004)

| # | Сценарий | Ожидаемый результат |
|---|----------|-------------------|
| D1 | Проверить структуру README.md | Все 5 секций присутствуют |
| D2 | Повторить Quick Start с нуля | Образ собран и запущен |
| D3 | Повторить API примеры | Все curl-команды возвращают ожидаемый ответ |

---

## 3. Регрессионное тестирование

| # | Сценарий | Ожидаемый результат |
|---|----------|-------------------|
| R1 | Существующий workflow `.github/workflows/docker.yml` | Проверяется на совместимость (branch master) |
| R2 | Образ запускается без параметров | `docker run --rm powerdns-server` не падает |

---

## 4. Автоматизация

- Автоматизация: минимальная (ручное тестирование через `docker run`)
- CI workflow существует, но требует обновления (IMAGE_NAME=llm-bridge — неверно)
- В scope текущего плана CI не обновляется

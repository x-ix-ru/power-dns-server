# План: Clean PowerDNS Docker Image

## Цель

Создать чистый, лёгкий, быстрый Docker-образ PowerDNS Authoritative Server.
Изображение является компонентом более крупного проекта с внешним Admin UI.
Скрипты управления в образ НЕ включаются.

---

## Список задач

| ID    | Название                           | Стек       | Описание                                         |
|-------|------------------------------------|------------|--------------------------------------------------|
| 001   | Обновить pdns.conf                 | Config     | api-key=secret, webserver-allow-from, чистка конфига |
| 002   | Оптимизировать Dockerfile          | DevOps     | Слить слои, .dockerignore, минимизация           |
| 003   | Проверить и усилить init.sh        | DevOps     | Idempotent init, edge cases, права               |
| 004   | Написать README.md                 | Docs       | Полная документация: запуск, настройки, API      |

---

## Порядок выполнения и зависимости

```
001 ──┐
002 ──┤
003 ──┼──> 004 (README пишется после всех изменений)
```

- **001**, **002**, **003** — независимые задачи, могут выполняться параллельно
- **004** — зависит от всех предыдущих (описывает финальное состояние)

### Критический путь

001/002/003 (параллельно) → 004

---

## Группы интеграционного тестирования

### Группа A: Build & Start (задачи 001 + 002 + 003)

Интеграционное тестирование сборки и запуска образа:

1. `docker build -t powerdns-server .` — образ собирается
2. `docker run --rm powerdns-server` — контейнер запускается и pdns_server работает
3. `docker image ls` — размер слоёв ≤ 30 MB
4. `docker run --rm powerdns-server cat /etc/pdns/pdns.conf` — api-key=secret, webserver-allow-from=0.0.0.0/0,::/0

### Группа B: API & DNS (задачи 001 + 002 + 003)

Функциональное тестирование API и DNS:

5. `curl http://localhost:80/api/v1/servers/localhost` — ответ 200, требуется X-API-Key: secret
6. DNS-запрос на порт 53 — сервер отвечает
7. `docker run --rm -v pdns-test:/var/lib/powerdns powerdns-server` — БД сохраняется в volume

### Группа C: Documentation (задача 004)

Проверка README:

8. README.md содержит секции: Quick Start, Default Settings, API Access, Persistence, Configuration
9. Примеры команд в README работают

---

## Ожидаемый результат

- [ ] Docker-образ собирается, размер ≤ 30 MB
- [ ] api-key=secret по умолчанию в pdns.conf
- [ ] webserver-allow-from=0.0.0.0/0,::/0 в pdns.conf
- [ ] init.sh создаёт БД idempotent-но, запускает pdns_server
- [ ] README.md содержит секции: Quick Start, Default Settings, API Access, Persistence, Configuration
- [ ] .dockerignore исключает лишние файлы из контекста сборки
- [ ] Образ не содержит скриптов управления (чистый компонент)

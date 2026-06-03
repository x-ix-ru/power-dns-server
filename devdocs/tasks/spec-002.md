# Спецификация задачи 002: Оптимизировать Dockerfile

## Описание

Оптимизировать Docker-образ для минимального размера и чистоты сборки.

## Полный контекст

Текущий `Dockerfile`:
- Alpine 3.21 (хорошо, оставляем)
- Два отдельных `RUN apk add` (можно слить)
- Нет `.dockerignore` (лишние файлы попадают в контекст)
- `WORKDIR /opt/pdns-admin` (можно оставить)
- `COPY pdns.conf` и `COPY init.sh` — правильно
- `sqlite` CLI остаётся (нужен для `init.sh`)

## Технические детали

### Dockerfile — оптимизации

1. **Слить `apk add` в один слой** — вместо двух `RUN apk add` сделать один:
   ```dockerfile
   RUN apk add --no-cache ca-certificates pdns pdns-backend-sqlite3 sqlite \
       && mkdir -p /var/lib/powerdns /var/run/pdns /etc/pdns \
       && chown -R pdns:pdns /var/lib/powerdns /var/run/pdns /etc/pdns
   ```

2. **Оптимизация COPY** — объединить COPY команды:
   ```dockerfile
   COPY pdns.conf /etc/pdns/pdns.conf
   COPY init.sh /opt/pdns-admin/init.sh
   ```

3. **chmod для init.sh** — убедиться, что файл executable, слить с предыдущим слоем или добавить в COPY:
   ```dockerfile
   RUN chmod +x /opt/pdns-admin/init.sh
   ```

### .dockerignore — новый файл

Содержание:
```
.git/
.github/
devdocs/
*.md
LICENSE
.dockerignore
```

Исключает из контекста сборки всё, что не нужно в образе.

### Финальная структура Dockerfile

```dockerfile
FROM alpine:3.21

RUN apk add --no-cache ca-certificates pdns pdns-backend-sqlite3 sqlite \
    && mkdir -p /var/lib/powerdns /var/run/pdns /etc/pdns \
    && chown -R pdns:pdns /var/lib/powerdns /var/run/pdns /etc/pdns

WORKDIR /opt/pdns-admin

COPY pdns.conf /etc/pdns/pdns.conf
COPY init.sh /opt/pdns-admin/init.sh

RUN chmod +x /opt/pdns-admin/init.sh

EXPOSE 53/udp 53/tcp 80/tcp

ENTRYPOINT ["/opt/pdns-admin/init.sh"]
```

## Файлы для изменения

| Файл | Действие |
|------|----------|
| `Dockerfile` | Edit — слои, оптимизация |
| `.dockerignore` | Create — новый файл |

## Требования к юнит-тестам

Нет (Dockerfile проверяется через build).

## Критерии приёмки

- [ ] `docker build -t powerdns-server .` собирается без ошибок
- [ ] Размер образа ≤ 30 MB (`docker image ls`)
- [ ] `.dockerignore` существует и исключает `.git/`, `*.md`, `devdocs/`, `LICENSE`
- [ ] В образе нет файлов из `.git/` и `devdocs/`
- [ ] Слой `apk add` — один RUN (не два)
- [ ] `init.sh` имеет execute permission в образе

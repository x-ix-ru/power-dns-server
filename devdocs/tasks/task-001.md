# Задача 001: Обновить pdns.conf

## Описание

Обновить конфигурационный файл `pdns.conf` для чистого Docker-образа PowerDNS:
- Установить `api-key=secret` по умолчанию (вместо текущего `changeme`)
- Убедиться, что `webserver-allow-from=0.0.0.0/0`
- Убрать излишние/неактуальные директивы

## Покрытие требований

- **spec.md §3.2** — Docker image defaults
- **spec.md §3.3** — Безопасность: API-ключ не `changeme`
- **Задача:** api-key=secret, webserver-allow-from=0.0.0.0/0

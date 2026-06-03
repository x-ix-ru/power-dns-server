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

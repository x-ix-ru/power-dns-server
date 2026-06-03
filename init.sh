#!/bin/sh

set -e
DB="/var/lib/powerdns/pdns.db"

if [ ! -f "$DB" ]; then
    sqlite3 "$DB" << 'SQL'
CREATE TABLE domains (
    id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    master VARCHAR(128) DEFAULT NULL,
    last_check INTEGER DEFAULT NULL,
    type VARCHAR(6) NOT NULL,
    notified_serial INTEGER UNSIGNED DEFAULT NULL,
    options VARCHAR(255) DEFAULT NULL,
    account VARCHAR(40) DEFAULT NULL,
    catalog VARCHAR(255) DEFAULT NULL
);
CREATE UNIQUE INDEX name_idx ON domains(name);

CREATE TABLE records (
    id INTEGER PRIMARY KEY,
    domain_id INTEGER DEFAULT NULL,
    name VARCHAR(255) DEFAULT NULL,
    type VARCHAR(10) DEFAULT NULL,
    content VARCHAR(64000) DEFAULT NULL,
    ttl INTEGER DEFAULT NULL,
    prio INTEGER DEFAULT NULL,
    disabled TINYINT(1) DEFAULT 0,
    ordername VARCHAR(255) DEFAULT NULL,
    auth TINYINT(1) DEFAULT 1
);
CREATE INDEX rec_name_idx ON records(name);
CREATE INDEX name_type_domain_idx ON records(name, type, domain_id);
CREATE INDEX domain_id_idx ON records(domain_id);
CREATE INDEX ordername_idx ON records(ordername);

CREATE TABLE supermasters (
    ip VARCHAR(64) NOT NULL,
    nameserver VARCHAR(255) NOT NULL,
    account VARCHAR(40) NOT NULL
);

CREATE TABLE comments (
    id INTEGER PRIMARY KEY,
    domain_id INTEGER NOT NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(10) NOT NULL,
    modified_at INTEGER NOT NULL DEFAULT 0,
    account VARCHAR(40) DEFAULT NULL,
    comment VARCHAR(64000) NOT NULL,
    satisfied_acl VARCHAR(255) DEFAULT NULL
);
CREATE INDEX expr_idx ON comments(domain_id, name, type);

CREATE TABLE domainmetadata (
    id INTEGER PRIMARY KEY,
    domain_id INTEGER NOT NULL,
    kind VARCHAR(32),
    content TEXT
);
CREATE INDEX domain_id_idx2 ON domainmetadata(domain_id);

CREATE TABLE cryptokeys (
    id INTEGER PRIMARY KEY,
    domain_id INTEGER NOT NULL,
    flags INTEGER NOT NULL,
    active BOOL,
    published BOOL DEFAULT 1,
    content TEXT
);

CREATE TABLE tsigkeys (
    id INTEGER PRIMARY KEY,
    name VARCHAR(255) DEFAULT NULL,
    algorithm VARCHAR(50) DEFAULT NULL,
    secret VARCHAR(512) DEFAULT NULL
);
CREATE INDEX domainid_idx ON domains(id);
SQL
    chown pdns:pdns "$DB"
    echo "Database initialized: $DB"
else
    echo "Database already exists: $DB"
fi

exec pdns_server --daemon=no --write-pid=no

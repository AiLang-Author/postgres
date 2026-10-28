PostgreSQL Database Management System
=====================================

## Haiku (branch `haiku-18.4`)

This branch is PostgreSQL 18.4 plus the fixes Haiku needs. It is not a
HaikuPorts pull request. Haiku developers can clone it and build it themselves.

Three runtime fixes are already in the commits:

- `psql` returns after a query. Haiku's `recv`/`send` ignore `SOCK_NONBLOCK`, so libpq uses `ioctl(FIONBIO)` and `MSG_DONTWAIT`.
- `to_char` and `money` do not hang. Haiku's `localeconv_l()` never returns, so PostgreSQL uses `localeconv()` instead.
- `'-0'::float8` stays negative zero, so float primary keys and foreign keys work.

The HaikuPorts port patchset (shared memory, libraries, template) is applied by the install script at build time. It is in `haiku/patches/`.

### Install on Haiku

```sh
git clone --depth 1 --branch haiku-18.4 https://github.com/AiLang-Author/postgres.git
cd postgres
sh haiku/install.sh
```

With only the script:

```sh
curl -fsSL -o /tmp/pg-haiku-install.sh \
  https://raw.githubusercontent.com/AiLang-Author/postgres/haiku-18.4/haiku/install.sh
sh /tmp/pg-haiku-install.sh
```

The script installs the compilers and libraries, applies the port patchset, builds, and installs into `/boot/home/config/non-packaged`. That directory is searched before the packaged `postgresql18`, so `psql` and `libpq` from this build are the ones you get.

It creates a database cluster at `/boot/home/pgdata` if you do not already have one, listens on `127.0.0.1`, and trusts local connections. If port 5432 is already in use, it uses 55432. A fresh cluster has a database named `postgres`. `psql` with no `-d` tries a database named after your Haiku user, which initdb does not create.

```sh
psql -h 127.0.0.1 -p 5432 -d postgres -c 'SELECT version();'
pg_ctl -D /boot/home/pgdata stop
```

`PREFIX`, `PGDATA`, and `PORT` override those paths and the port.

### Install the prebuilt x86_64 package

If you do not want to compile, download the release tarball. It is PostgreSQL 18.4 built on Haiku r1beta6 x86_64, with the port and the three runtime fixes already in the binaries. Unpack it over the non-packaged prefix. Haiku searches that prefix before the packaged `postgresql18`.

```sh
cd /boot/home/config/non-packaged
curl -fsSL -L -o /tmp/postgresql-18.4-haiku-x86_64.tar.xz \
  https://github.com/AiLang-Author/postgres/releases/download/postgresql-18.4-haiku/postgresql-18.4-haiku-x86_64.tar.xz
tar -xJf /tmp/postgresql-18.4-haiku-x86_64.tar.xz
```

The archive has `bin/`, `lib/`, `include/`, and `share/`. It does not contain a database cluster. SHA256 `6ed0ca2df0306072197c579298621794b117bd4d6b1fb38565db5146753ff04e`. Create a cluster and start the server:

```sh
PREFIX=/boot/home/config/non-packaged
PGDATA=/boot/home/pgdata
"$PREFIX/bin/initdb" -D "$PGDATA" --encoding=UTF8 --no-locale \
  --auth-local=trust --auth-host=trust --username="$(id -un)"
printf '%s\n' "listen_addresses = '127.0.0.1'" "port = 5432" \
  "unix_socket_directories = '/tmp'" >> "$PGDATA/postgresql.conf"
"$PREFIX/bin/pg_ctl" -D "$PGDATA" -l "$PGDATA/logfile" start
"$PREFIX/bin/psql" -h 127.0.0.1 -p 5432 -d postgres -c 'SELECT version();'
```

Stop it with `pg_ctl -D /boot/home/pgdata stop`. The release page is <https://github.com/AiLang-Author/postgres/releases/tag/postgresql-18.4-haiku>. This is not an official PostgreSQL or HaikuPorts package.

### Build with haikuporter instead

Copy `haiku/postgresql18-18.4.recipe` over `dev-db/postgresql/postgresql18-18.4.recipe` in a local haikuports tree, and copy `haiku/patches/*` into `dev-db/postgresql/patches/`. The recipe downloads the official 18.4 tarball and applies the port patchset plus the three fixes. Do not send that tree to HaikuPorts.

### Upstream PostgreSQL

This directory contains the source code distribution of the PostgreSQL
database management system.

PostgreSQL is an advanced object-relational database management system
that supports an extended subset of the SQL standard, including
transactions, foreign keys, subqueries, triggers, user-defined types
and functions.  This distribution also contains C language bindings.

Copyright and license information can be found in the file COPYRIGHT.

General documentation about this version of PostgreSQL can be found at
<https://www.postgresql.org/docs/18/>.  In particular, information
about building PostgreSQL from the source code can be found at
<https://www.postgresql.org/docs/18/installation.html>.

The latest version of this software, and related software, may be
obtained at <https://www.postgresql.org/download/>.  For more information
look at our web site located at <https://www.postgresql.org/>.

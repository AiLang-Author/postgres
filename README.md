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

It creates a database cluster at `/boot/home/pgdata` if you do not already have one, listens on `127.0.0.1`, and trusts local connections. If port 5432 is already in use, it uses 55432.

```sh
psql -h 127.0.0.1 -p 5432 -c 'SELECT version();'
pg_ctl -D /boot/home/pgdata stop
```

`PREFIX`, `PGDATA`, and `PORT` override those paths and the port.

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

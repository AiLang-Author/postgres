#!/bin/sh
# Download, build, and install PostgreSQL 18.4 on Haiku.
#
# The runtime fixes (nonblocking sockets, localeconv_l, negative zero) are
# already committed on branch haiku-18.4. This script applies the HaikuPorts
# 18.4 port patchset so the tree compiles, then installs it under
# /boot/home/config/non-packaged, which Haiku searches before the packaged
# postgresql18. Nothing is sent to HaikuPorts.
#
# The port patchset is theirs (Augustin Cavalier, begasus, Mikhail Titov,
# adapted from Mark Hellegers). It lives in haiku/patches/ only so this
# build does not depend on a HaikuPorts pull request.
#
# From Haiku, either:
#   git clone --depth 1 --branch haiku-18.4 https://github.com/AiLang-Author/postgres.git
#   cd postgres && sh haiku/install.sh
# or, with just this file:
#   curl -fsSL -o /tmp/pg-haiku-install.sh \
#     https://raw.githubusercontent.com/AiLang-Author/postgres/haiku-18.4/haiku/install.sh
#   sh /tmp/pg-haiku-install.sh
#
# PREFIX, PGDATA, and PORT override the defaults.
# A cluster is created at /boot/home/pgdata and started on 127.0.0.1.
# If something is already listening on 5432, the new server uses 55432.

set -eu

PREFIX="${PREFIX:-/boot/home/config/non-packaged}"
PGDATA="${PGDATA:-/boot/home/pgdata}"
REPO_URL="https://github.com/AiLang-Author/postgres.git"
BRANCH="haiku-18.4"

if [ "$(uname -s 2>/dev/null || echo unknown)" != Haiku ] && [ ! -d /boot/system ]; then
	echo "This script installs PostgreSQL on Haiku." >&2
	exit 1
fi

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
if [ -f "$script_dir/../configure.ac" ]; then
	cd "$script_dir/.."
elif [ -f ./configure.ac ]; then
	:
else
	dest="$HOME/postgres"
	if [ ! -f "$dest/configure.ac" ]; then
		git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$dest"
	fi
	exec sh "$dest/haiku/install.sh"
fi

if [ ! -f src/port/pg_localeconv_r.c ] || ! grep -q 'Haiku advertises localeconv_l' src/port/pg_localeconv_r.c; then
	echo "This tree is not the haiku-18.4 branch. The runtime fixes are missing." >&2
	exit 1
fi

echo "=== build dependencies ==="
pkgman install -y \
	haiku_devel \
	gcc \
	make \
	bison \
	flex \
	libtool \
	m4 \
	perl \
	pkgconfig \
	autoconf2.71 \
	openssl3_devel \
	icu74_devel \
	openldap_devel \
	openpam_devel \
	readline_devel \
	libxml2_devel \
	libxslt_devel \
	zlib_devel

AUTOCONF=""
for c in autoconf-2.71 autoconf2.71; do
	if command -v "$c" >/dev/null 2>&1; then
		AUTOCONF=$c
		break
	fi
done
if [ -z "$AUTOCONF" ]; then
	echo "autoconf 2.71 is required. Package autoconf2.71 did not provide it." >&2
	exit 1
fi

if [ ! -f src/backend/port/haiku/shm.c ]; then
	echo "=== apply HaikuPorts port patchset ==="
	if [ ! -d .git ]; then
		echo "git clone this branch. git am needs a repository to apply the port patchset." >&2
		exit 1
	fi
	git -c user.name="Haiku PostgreSQL install" \
		-c user.email="install@localhost" \
		-c apply.whitespace=nowarn \
		am haiku/patches/postgresql18-18.4.patchset
fi

echo "=== configure ==="
touch src/template/haiku
libtoolize --force --copy --install || true
# libtoolize can drop config/missing. PostgreSQL's own script has to stay.
if [ ! -s config/missing ]; then
	git checkout -- config/missing
fi
"$AUTOCONF"

jobs=1
if command -v nproc >/dev/null 2>&1; then
	jobs=$(nproc)
fi

CFLAGS="-D_BSD_SOURCE -O2" LDFLAGS="-lnetwork" \
	./configure \
		--prefix="$PREFIX" \
		--bindir="$PREFIX/bin" \
		--with-icu \
		--with-ldap \
		--with-libxml \
		--with-libxslt \
		--with-openssl \
		--with-pam \
		--with-template=haiku \
		--disable-static

echo "=== make -j$jobs ==="
make -j"$jobs"
make install

export PATH="$PREFIX/bin:$PATH"
hash -r 2>/dev/null || true

if [ -z "${PORT:-}" ]; then
	PORT=5432
	if netstat -n -a 2>/dev/null | grep -E '(^|[^0-9])5432([^0-9]|$)' >/dev/null; then
		PORT=55432
		echo "Port 5432 is in use. This server will listen on $PORT."
	fi
fi

export PAGER=cat
export PSQL_PAGER=cat
export PGGSSENCMODE=disable
export PGSSLMODE=disable

if [ ! -f "$PGDATA/PG_VERSION" ]; then
	echo "=== initdb $PGDATA ==="
	mkdir -p "$PGDATA"
	"$PREFIX/bin/initdb" -D "$PGDATA" --encoding=UTF8 --no-locale \
		--auth-local=trust --auth-host=trust --username="$(id -un)"
	cat >> "$PGDATA/postgresql.conf" <<EOF
listen_addresses = '127.0.0.1'
port = $PORT
unix_socket_directories = '/tmp'
EOF
else
	echo "=== cluster already at $PGDATA ==="
fi

echo "=== start ==="
if "$PREFIX/bin/pg_ctl" -D "$PGDATA" status >/dev/null 2>&1; then
	echo "Server already running."
else
	"$PREFIX/bin/pg_ctl" -D "$PGDATA" -l "$PGDATA/logfile" start
	sleep 2
fi

echo "=== psql ==="
"$PREFIX/bin/psql" -h 127.0.0.1 -p "$PORT" -c 'SELECT version();' &
psql_pid=$!
i=0
while kill -0 "$psql_pid" 2>/dev/null; do
	i=$((i + 1))
	if [ "$i" -gt 20 ]; then
		kill "$psql_pid" 2>/dev/null || true
		echo "psql did not return. See $PGDATA/logfile" >&2
		exit 1
	fi
	sleep 1
done
wait "$psql_pid"

echo
echo "Installed: $PREFIX/bin"
echo "Data:      $PGDATA"
echo "Connect:   psql -h 127.0.0.1 -p $PORT"
echo "Stop:      pg_ctl -D $PGDATA stop"

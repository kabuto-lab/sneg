#!/usr/bin/env bash
set -Eeuo pipefail
export NEXT_TELEMETRY_DISABLED=1
ROOT=/opt/sneg
REPOSITORY=https://github.com/kabuto-lab/sneg.git
REVISION=${1:?Pass the full published commit SHA}
[[ "$REVISION" =~ ^[0-9a-f]{40}$ ]] || { echo 'Invalid commit SHA' >&2; exit 1; }
[[ $(id -u) == 0 ]] || { echo 'Run as root on the VPS' >&2; exit 1; }
install -d "$ROOT/releases" "$ROOT/backups"
exec 9>"$ROOT/deploy.lock"
flock -n 9 || { echo 'Another deployment is running' >&2; exit 1; }
if [[ ! -d "$ROOT/repository/.git" ]]; then
    git clone "$REPOSITORY" "$ROOT/repository"
fi
[[ $(git -C "$ROOT/repository" remote get-url origin) == "$REPOSITORY" ]]
git -C "$ROOT/repository" fetch origin main
git -C "$ROOT/repository" merge-base --is-ancestor "$REVISION" origin/main
RELEASE="$ROOT/releases/$REVISION"
install -d "$RELEASE"
[[ $(realpath "$RELEASE") == "$ROOT/releases/$REVISION" ]]
PROBE_PID=
ACTIVATED=0
BACKUP=
PREVIOUS=
cleanup() {
    if [[ -n "$PROBE_PID" ]]; then
        kill "$PROBE_PID" 2>/dev/null || true
        wait "$PROBE_PID" 2>/dev/null || true
    fi
}
rollback() {
    local result=$?
    trap - ERR
    cleanup
    if [[ "$ACTIVATED" == 1 ]]; then
        echo 'New release failed; restoring previous service.' >&2
        if [[ -n "$PREVIOUS" ]]; then
            ln -sfn "$PREVIOUS" "$ROOT/current.next"
            mv -Tf "$ROOT/current.next" "$ROOT/current"
        fi
        cp -p "$BACKUP/snegurochka-next.service" /etc/systemd/system/snegurochka-next.service
        systemctl daemon-reload
        systemctl restart snegurochka-next.service
    fi
    exit "$result"
}
trap cleanup EXIT
trap rollback ERR
if [[ ! -f "$RELEASE/.release-ready" ]]; then
    git -C "$ROOT/repository" archive "$REVISION" | tar -x -C "$RELEASE"
    cd "$RELEASE"
    NODE_ENV=development corepack yarn install --frozen-lockfile --non-interactive
    NODE_ENV=production corepack yarn build
    printf '%s\n' "$REVISION" > "$RELEASE/RELEASE_COMMIT"
    PROBE_PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')
    NODE_ENV=production node node_modules/next/dist/bin/next start -H 127.0.0.1 -p "$PROBE_PORT" > "$RELEASE/probe.log" 2>&1 &
    PROBE_PID=$!
    for attempt in $(seq 1 40); do
        if curl -fsS "http://127.0.0.1:$PROBE_PORT/" -o /dev/null 2>/dev/null; then break; fi
        kill -0 "$PROBE_PID"
        sleep 1
    done
    for path in / /vacancies /snegurochka-white.svg /hero/magnific_6AXn595iJO.avif; do
        curl -fsS -H 'Host: snegurochkimoscow.com' "http://127.0.0.1:$PROBE_PORT$path" -o /dev/null
    done
    cleanup
    PROBE_PID=
    touch "$RELEASE/.release-ready"
    chown -R www-data:www-data "$RELEASE"
fi
BACKUP="$ROOT/backups/app-$(date -u +%Y%m%dT%H%M%SZ)-${REVISION:0:8}"
install -d "$BACKUP"
cp -p /etc/systemd/system/snegurochka-next.service "$BACKUP/snegurochka-next.service"
if [[ -L "$ROOT/current" ]]; then PREVIOUS=$(readlink -f "$ROOT/current"); fi
printf '%s\n' "${PREVIOUS:-/opt/ext-snegurochka}" > "$BACKUP/previous-release.txt"
ln -sfn "$RELEASE" "$ROOT/current.next"
mv -Tf "$ROOT/current.next" "$ROOT/current"
ACTIVATED=1
install -m 644 "$RELEASE/ops/server/snegurochka-next.service" /etc/systemd/system/snegurochka-next.service
systemctl daemon-reload
systemctl restart snegurochka-next.service
for attempt in $(seq 1 40); do
    if curl -fsS http://127.0.0.1:5134/ -o /dev/null 2>/dev/null; then break; fi
    sleep 1
done
systemctl is-active --quiet snegurochka-next.service
for path in / /vacancies /snegurochka-white.svg; do
    curl -fsS -H 'Host: snegurochkimoscow.com' "http://127.0.0.1:5134$path" -o /dev/null
done
ACTIVATED=0
printf 'DEPLOYED %s\nCURRENT %s\nBACKUP %s\n' "$REVISION" "$RELEASE" "$BACKUP"

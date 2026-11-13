#!/usr/bin/env python3
"""Switch only the two Snegurochki vhosts, retaining a rollback copy."""
import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess
import time
import urllib.request


def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout.strip()


def check_hosts():
    for host in ('snegurochkimoscow.ru', 'www.snegurochkimoscow.ru', 'www.snegurochkimoscow.com'):
        for scheme in ('http', 'https'):
            result = run('curl', '--noproxy', '*', '--max-time', '15', '--resolve',
                         f'{host}:{443 if scheme == "https" else 80}:127.0.0.1',
                         '-sS', '-o', '/dev/null', '-w', '%{http_code} %{redirect_url}',
                         f'{scheme}://{host}/vacancies?source=migration&test=1')
            assert result == '301 https://snegurochkimoscow.com/vacancies?source=migration&test=1', result
    for path in ('/', '/vacancies', '/snegurochka-white.svg'):
        result = run('curl', '--noproxy', '*', '--max-time', '15', '--resolve',
                     'snegurochkimoscow.com:443:127.0.0.1', '-sS', '-o', '/dev/null',
                     '-w', '%{http_code}', 'https://snegurochkimoscow.com' + path)
        assert result == '200', (path, result)


def main():
    if os.geteuid() != 0:
        raise SystemExit('Run as root on the VPS')
    with urllib.request.urlopen('http://127.0.0.1:5134/', timeout=10) as response:
        assert response.status == 200
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    backup = Path('/opt/sneg/backups') / ('domains-' + stamp)
    backup.mkdir(parents=True, exist_ok=False)
    source = Path(__file__).resolve().parent / 'nginx'
    targets = {
        'snegurochkimoscow.ru.conf': Path('/etc/nginx/sites-enabled/snegurochkimoscow.ru').resolve(strict=True),
        'snegurochkimoscow.com.conf': Path('/etc/nginx/sites-enabled/snegurochkimoscow.com').resolve(strict=True),
    }
    for name, target in targets.items():
        if not target.is_relative_to('/etc/nginx'):
            raise RuntimeError(f'Unexpected nginx target: {target}')
        shutil.copy2(target, backup / name)
    (backup / 'targets.json').write_text(json.dumps({k: str(v) for k, v in targets.items()}, indent=2))
    try:
        for name, target in targets.items():
            shutil.copyfile(source / name, target)
        run('nginx', '-t')
        run('systemctl', 'reload', 'nginx')
        for attempt in range(10):
            try:
                check_hosts()
                break
            except (AssertionError, subprocess.CalledProcessError):
                if attempt == 9:
                    raise
                time.sleep(0.5)
    except BaseException:
        for name, target in targets.items():
            shutil.copy2(backup / name, target)
        run('nginx', '-t')
        run('systemctl', 'reload', 'nginx')
        raise
    print(json.dumps({'status': 'activated', 'canonical': 'https://snegurochkimoscow.com',
                      'backup': str(backup)}, indent=2))


if __name__ == '__main__':
    main()

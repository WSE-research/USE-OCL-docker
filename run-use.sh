#!/usr/bin/env bash
#
# run-use.sh -- startet USE (UML-based Specification Environment) 7.5 in einem
# Container, ohne lokale Installation von USE oder Java 21. Benötigt wird nur
# Docker oder Podman; das Skript nimmt, was nutzbar ist (zuerst Docker).
#
# Aufruf: ./run-use.sh [modell.use [skript.soil]]           grafische Oberfläche
#         ./run-use.sh -nogui [modell.use [skript.soil]]    USE-Shell im Terminal
#         ./run-use.sh --rebuild [...]                      Image vorher neu bauen
#
# Weitere Optionen werden an USE durchgereicht (z. B. -nr, -q, -h). Das aktuelle
# Verzeichnis ist im Container /work: Dateien müssen darin liegen und werden
# relativ angegeben. Das Image (use-ocl:7.5.0) wird beim ersten Aufruf aus
# use-docker/Dockerfile gebaut. Mit USE_ENGINE=docker oder USE_ENGINE=podman
# lässt sich das Werkzeug fest vorgeben. Ist der Standardspeicher von Podman
# nicht nutzbar, legt das Skript einen eigenen an (/var/tmp/use-ocl-<uid>,
# änderbar mit USE_PODMAN_STORE; sollte auf einer lokalen Platte liegen, nicht
# auf NFS).

set -euo pipefail

IMAGE="use-ocl:7.5.0"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Container-Werkzeug wählen: das erste, das installiert ist und läuft
candidates=(docker podman)
if [[ -n ${USE_ENGINE:-} ]]; then
  if ! command -v "$USE_ENGINE" >/dev/null 2>&1; then
    echo "USE_ENGINE=$USE_ENGINE: Programm nicht gefunden." >&2
    exit 1
  fi
  candidates=("$USE_ENGINE")
fi
engine=()
for c in "${candidates[@]}"; do
  if command -v "$c" >/dev/null 2>&1 && "$c" info >/dev/null 2>&1; then
    engine=("$c")
    break
  fi
done
# Podman ohne nutzbaren Standardspeicher (z. B. ein gemeinsamer, fremder
# rootless_storage_path): eigener Speicher auf einer lokalen Platte. Ohne
# subuid-Bereiche gibt es nur die eigene Kennung, dann Besitzerwechsel beim
# Auspacken der Images überspringen.
if (( ${#engine[@]} == 0 )); then
  for c in "${candidates[@]}"; do
    command -v "$c" >/dev/null 2>&1 && "$c" --version 2>/dev/null | grep -qi podman || continue
    store=${USE_PODMAN_STORE:-/var/tmp/use-ocl-$(id -u)}
    run=${XDG_RUNTIME_DIR:-/tmp}/use-ocl-$(id -u)
    mkdir -p "$store" "$run"
    engine=("$c" --root "$store/storage" --runroot "$run" --storage-opt ignore_chown_errors=true)
    if "${engine[@]}" info >/dev/null 2>&1; then
      echo "Hinweis: Podman nutzt den eigenen Speicher $store." >&2
      break
    fi
    engine=()
  done
fi
if (( ${#engine[@]} == 0 )); then
  echo "Weder Docker noch Podman ist nutzbar. Bitte eines davon installieren" >&2
  echo "(bei Docker: Dienst gestartet und Benutzer in der Gruppe docker?)." >&2
  exit 1
fi
# "docker" kann Podman sein (Paket podman-docker) und umgekehrt
if "${engine[0]}" --version 2>/dev/null | grep -qi podman; then flavor=podman; else flavor=docker; fi

if [[ ${1:-} == --rebuild ]]; then
  shift
  "${engine[@]}" build -t "$IMAGE" "$HERE/use-docker"
elif ! "${engine[@]}" image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Baue das Image $IMAGE mit ${engine[0]} (einmalig, lädt USE von GitHub) ..." >&2
  "${engine[@]}" build -t "$IMAGE" "$HERE/use-docker"
fi

args=(--rm -i -e HOME=/tmp -v "$PWD:/work" -w /work)
# Dateien in /work sollen dem eigenen Benutzer gehören. Bei rootless Podman ist
# root im Container der eigene Benutzer; sonst mit --user die eigene Kennung.
if [[ $flavor == podman && $("${engine[@]}" info --format '{{.Host.Security.Rootless}}' 2>/dev/null) == true ]]; then
  :
else
  args+=(--user "$(id -u):$(id -g)")
fi
# Mit SELinux (Fedora, RHEL) darf der Container das Verzeichnis sonst nicht lesen
if command -v selinuxenabled >/dev/null 2>&1 && selinuxenabled; then
  args+=(--security-opt label=disable)
fi
[[ -t 0 && -t 1 ]] && args+=(-t)

gui=1
for a in "$@"; do [[ $a == -nogui ]] && gui=0; done

if (( gui )); then
  if [[ -z ${DISPLAY:-} ]]; then
    echo "Keine grafische Sitzung (DISPLAY ist leer). Ohne Oberfläche: $0 -nogui ..." >&2
    exit 1
  fi
  # X11-Socket und Cookie des Hosts; gleicher Hostname, damit das Cookie passt
  xauth_file="${XAUTHORITY:-$HOME/.Xauthority}"
  args+=(-e DISPLAY --hostname "$(hostname)" -v /tmp/.X11-unix:/tmp/.X11-unix:ro)
  if [[ -f $xauth_file ]]; then
    args+=(-e XAUTHORITY=/tmp/.Xauthority -v "$xauth_file:/tmp/.Xauthority:ro")
  fi
fi

exec "${engine[@]}" run "${args[@]}" "$IMAGE" "$@"

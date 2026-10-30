# USE (UML-based Specification Environment, Universität Bremen) in einem Container.
# Gebaut und gestartet von ../run-use.sh; USE 7.5 benötigt Java 21.
# voll qualifiziert, damit Podman ohne Suchliste für Kurznamen auskommt
FROM docker.io/library/eclipse-temurin:21-jre-noble

# X11-Bibliotheken und Schriften für die grafische Oberfläche (Swing).
# apt lädt ohne Benutzerwechsel nach _apt: Rootless Podman ohne subuid-Bereiche
# kennt im Container nur root, der Wechsel scheitert dort.
RUN echo 'APT::Sandbox::User "root";' > /etc/apt/apt.conf.d/99-ohne-sandbox \
 && apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip \
      libxext6 libxrender1 libxtst6 libxi6 fontconfig fonts-dejavu-core \
 && rm -rf /var/lib/apt/lists/*

# erst hier, damit alle Versionen die Schicht darüber teilen
ARG USE_VERSION=7.5.0
# leer: Prüfsumme aus der Liste der bekannten Versionen unten
ARG USE_SHA256=
# Offizielles Release von GitHub, gegen die Prüfsumme geprüft. Die Dateinamen
# der Releases sind nicht einheitlich; für die bekannten Versionen stehen Datei
# und Prüfsumme in der Liste (berechnet aus den Releases auf GitHub, für 7.5.0
# identisch mit dem Digest dort), für andere Versionen USE_SHA256 angeben.
# Ein hängender Download bricht nach einer Minute unter 1 kB/s ab und wird
# wiederholt.
RUN case "$USE_VERSION" in \
      7.5.0) zip=use-7.5.0-use-bin.zip sha=9b5a49d1d2345e65d1da8518008887e8bc12df388b6eef08228c5a1052618d10 ;; \
      7.1.1) zip=use-7.1.1.zip         sha=fbbc329da929cbe594765b7cf5e8d9d072d379357e60f66053df24967175d7a3 ;; \
      7.1.0) zip=use-7.1.0.zip         sha=57efdf82c45326c7dd696d5d11721263024c4b084bec28f1a368033cb2cfdada ;; \
      7.0.1) zip=use-7.0.1.zip         sha=d50cbe1194569a47d271633a6fb8ccc4a8adc88fb085dc5f161fa0be9539de56 ;; \
      *)     zip=use-${USE_VERSION}-use-bin.zip sha= ;; \
    esac \
 && sha=${USE_SHA256:-$sha} \
 && if [ -z "$sha" ]; then \
      echo "USE $USE_VERSION: Prüfsumme unbekannt, bitte USE_SHA256 angeben (steht auf der Release-Seite bei der Datei)." >&2; \
      exit 1; \
    fi \
 && curl -fsSL --connect-timeout 30 --speed-limit 1000 --speed-time 60 \
      --retry 3 --retry-delay 5 --retry-all-errors -o /tmp/use.zip \
      "https://github.com/useocl/use/releases/download/v${USE_VERSION}/${zip}" \
 && echo "${sha}  /tmp/use.zip" | sha256sum -c - \
 && unzip -q /tmp/use.zip -d /tmp/use \
 && mv /tmp/use/use-* /opt/use \
 && rm -rf /tmp/use.zip /tmp/use

ENV LD_LIBRARY_PATH=/opt/use/lib
WORKDIR /work
# -nr: USE bringt für Linux keine GNU-Readline-Bibliothek mit, ohne den Schalter warnt es bei jedem Start
ENTRYPOINT ["java", "-Dawt.useSystemAAFontSettings=on", "-jar", "/opt/use/lib/use-gui.jar", "-nr"]

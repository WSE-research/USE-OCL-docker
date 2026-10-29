# USE-OCL-docker

Startet [USE](https://github.com/useocl/use) 7.5 (UML-based Specification Environment, Universität Bremen) in einem Container, ohne USE oder Java 21 zu installieren. Benötigt wird nur Docker oder Podman; `run-use.sh` nimmt, was nutzbar ist (zuerst Docker).

## Aufruf

```
./run-use.sh [modell.use [skript.soil]]           grafische Oberfläche
./run-use.sh -nogui [modell.use [skript.soil]]    USE-Shell im Terminal
./run-use.sh --rebuild [...]                      Image vorher neu bauen
```

Das aktuelle Verzeichnis ist im Container `/work`: Modell und Skript müssen darin liegen und werden relativ angegeben. Weitere Optionen gehen an USE, etwa `-q` (Invarianten prüfen, Exit-Code 1 bei Verletzung) oder `-h`.

Beim ersten Aufruf baut das Skript das Image `use-ocl:7.5.0` aus `use-docker/Dockerfile`. Dabei lädt es das Basis-Image (Eclipse Temurin 21) und das USE-Release von GitHub, dessen Prüfsumme es kontrolliert; das dauert je nach Netz einige Minuten.

Die grafische Oberfläche nutzt die X11-Sitzung des Rechners (Linux mit X11 oder XWayland). Ohne grafische Sitzung, etwa über SSH, mit `-nogui` arbeiten.

## Docker oder Podman

- `USE_ENGINE=docker` oder `USE_ENGINE=podman` legt das Werkzeug fest.
- Mit rootless Podman gehören Dateien, die USE in `/work` schreibt, dem eigenen Benutzer; mit Docker sorgt `--user` dafür.
- Auf Rechnern mit SELinux (Fedora, RHEL) setzt das Skript `--security-opt label=disable`.

## PCs im Hochschulnetz

Auf den Linux-PCs (Debian 12, Podman 4.3, Home-Verzeichnis auf NFS, keine subuid-Bereiche) ist der Standardspeicher von Podman nicht nutzbar. Das Skript legt dann einen eigenen Speicher unter `/var/tmp/use-ocl-<uid>` an und meldet das mit einem Hinweis. Dieser Speicher liegt auf der lokalen Platte des PCs: An jedem PC wird das Image beim ersten Aufruf neu gebaut. Mit `USE_PODMAN_STORE` lässt sich ein anderer Ort wählen; er darf nicht auf NFS liegen.

## Siehe auch

[USE-OCL-vscode](https://github.com/WSE-research/USE-OCL-vscode): Erweiterung für Visual Studio Code, die `.use`- und `.soil`-Dateien hervorhebt und mit USE prüft; sie nutzt dasselbe Image.

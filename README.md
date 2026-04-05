# homeassistant-dozzle

[![GitHub](https://img.shields.io/badge/GitHub-Erreur32%2Fhomeassistant--dozzle-181717?logo=github)](https://github.com/Erreur32/homeassistant-dozzle)
[![Dozzle upstream](https://img.shields.io/badge/upstream-amir20%2Fdozzle-2496ED?logo=github)](https://github.com/amir20/dozzle)

App **Home Assistant** (ex add-on) qui embarque **[Dozzle](https://github.com/amir20/dozzle)** : visionneur de journaux Docker en temps réel, avec **Ingress**, option **agent** et build **multi-arch** via GitHub Actions.

| Élément | Emplacement |
|--------|-------------|
| Manifest & image | [`dozzle/config.yaml`](dozzle/config.yaml) |
| Documentation utilisateur | [`dozzle/DOCS.md`](dozzle/DOCS.md) |
| Journal des versions | [`dozzle/CHANGELOG.md`](dozzle/CHANGELOG.md) |
| Dépôt d’apps (Supervisor) | [`repository.yaml`](repository.yaml) |

## Ajouter le dépôt dans Home Assistant

1. **Paramètres** → **Apps** → menu **⋮** → **Dépôts d’applications**.
2. Ajouter l’URL : `https://github.com/Erreur32/homeassistant-dozzle`
3. Installer l’app **Dozzle** depuis la boutique.

## Image conteneur (GHCR)

Les workflows poussent une image multi-arch correspondant à la clé `image` du manifest, par défaut :

`ghcr.io/erreur32/homeassistant-dozzle`

(alignée sur le nom du dépôt GitHub ; le package doit être lié au dépôt côté GitHub Packages.)

## Développement — pousser un dépôt existant

**Important :** les commandes `git remote` / `git push` ne fonctionnent que **dans un dossier où `git init` a déjà été fait** (présence d’un répertoire `.git`). Sinon : *« ni ceci ni aucun de ses parents n’est un dépôt git »*.

Si le dépôt GitHub est vide ou vous réinitialisez l’historique :

```bash
cd /chemin/vers/HA_dozzle
git init
git add -A
git commit -m "Initial commit: app Dozzle Home Assistant"
git remote add origin https://github.com/Erreur32/homeassistant-dozzle.git
git branch -M main
git push -u origin main
```

### Partage réseau (NFS, SMB, \\…) et `GIT_DISCOVERY_ACROSS_FILESYSTEM`

Si Git affiche *« Arrêt à la limite du système de fichiers »* ou ne trouve pas `.git` alors qu’il est sur un autre montage :

```bash
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1
```

(à placer dans votre `~/.bashrc` si besoin), ou travaillez dans un clone sur un disque local puis poussez depuis là.

Si **`origin`** existe déjà :

```bash
git remote set-url origin https://github.com/Erreur32/homeassistant-dozzle.git
git branch -M main
git push -u origin main
```

## Version du projet

Script utilitaire à la racine : [`update_version.sh`](update_version.sh) (bump `dozzle/config.yaml`, `ARG BUILD_VERSION` dans le Dockerfile, option `--tag-push`).

## Liens

- Dépôt : [github.com/Erreur32/homeassistant-dozzle](https://github.com/Erreur32/homeassistant-dozzle)
- Dozzle (amont) : [github.com/amir20/dozzle](https://github.com/amir20/dozzle)
- Documentation développeur HA — Apps : [developers.home-assistant.io/docs/apps](https://developers.home-assistant.io/docs/apps/)

# 🛠 Gulp-Kirby Starter Kit — Documentation

## 1. Introduction
Ce projet combine Kirby CMS avec une stack Docker (Nginx + PHP‑FPM). Il fournit un environnement reproductible pour le développement et l’onboarding rapide.

Le **Gulp-Kirby Starter Kit** est un boilerplate permettant de démarrer rapidement un projet **Kirby CMS (v3)** avec une chaîne de build front basée sur **Gulp v4**.

Il propose notamment :

- Compilation **Sass/CSS**
- Minification **HTML / CSS / JS**
- Optimisation des **images**
- Génération de **sprites SVG**
- Création de **favicons**
- **Font subsetting** (réduction du poids des polices)
- **Cache busting** via fingerprinting + intégration avec Kirby
- **Serveur de développement** intégré (PHP / proxy / BrowserSync)
- Structure **modulaire** via des tâches Gulp séparées
- **Configuration centralisée** dans `config.js`

## Stack & services

### Fichier
- **`docker-compose.yml`**

### Services
- **nginx (web)**
  - Image : `nginx:stable`
  - Écoute : `:80` (exposé sur l’hôte en `:80`)
  - Docroot : `/app`

- **php (php-fpm)**
  - Image : `php:8.2-fpm-alpine`
  - Communication avec Nginx via **socket Unix** (volume `sock`)
  - Extensions : `gd`, `imagick` (PECL), etc.

### Volumes partagés
- `sock` → `/sock` — socket Unix partagé Nginx ↔ PHP-FPM  
- `./htdocs` → `/app` — code, contenu, `vendor/`, `index.php`

### Notes
- **nginx** sert l’application depuis **`/app`** (mode “(1) : `index.php` dans `htdocs/`”).  
- **php** exécute **PHP-FPM 8.2** ; le même dossier hôte est monté dans **`/app`**.

### URL par défaut
- **http://localhost** (port `80`)  
  > Ajustable via `docker-compose.yml` (clé `ports`, ex. `"80:80"`).


## Prérequis d’installation (poste dev)

Docker Engine/Desktop 24+ avec Docker Compose v2.20+.

## Schéma de l’infra
![schéma infra](./assets/img/image-1.png)


## Références

Repo Starter: S1SYPHOS/Gulp-Kirby-Starter-Kit

Kirby CMS docs: getkirby.com (installation, panel, configuration)

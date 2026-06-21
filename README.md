# NEXUM FLOW – Catalogue de Workflows n8n

Bibliothèque de workflows n8n réutilisables pour agences de développement et PME/TPE.

## Vue d'ensemble

| Catégorie | Workflows | Priorité |
|-----------|-----------|----------|
| 01 – Leads | Centralisation formulaires, Qualification IA | P1 |
| 02 – Commercial | Relances devis, Génération devis, Pipeline IA | P1 / P2 |
| 03 – Client | Dossiers clients, Sync CRM/Agenda, Assistant RDV | P1 |
| 04 – Administratif | Factures, Impayés, Documents IA | P1 / P2 |
| 05 – IA | Traitement emails, Résumés réunions, Dashboard direction | P1 / P2 |
| 06 – Marketing | Avis clients, Contenu SEO, Réputation | P3 |
| 07 – Veille | Veille concurrentielle, Veille technologique | P2 |
| 08 – RH | Tri CV, Onboarding | – |

**Total : 18 workflows prêts à importer**

---

## Stack technique

```
n8n          – Orchestrateur de workflows
PostgreSQL   – Base de données principale
Redis        – Queue d'exécution
FastAPI      – API métier (PDF, stockage, extraction)
MinIO        – Stockage de fichiers (S3-compatible)
Traefik      – Reverse proxy + SSL automatique
OpenAI       – GPT-4o pour l'IA
Docker       – Conteneurisation
```

---

## Démarrage rapide

### 1. Cloner et configurer

```bash
git clone https://github.com/rococo77/nexum-flow.git
cd nexum-flow

# Copier et éditer les variables d'environnement
cp docker/.env.example docker/.env
nano docker/.env
```

### 2. Lancer l'infrastructure

```bash
./scripts/setup.sh
```

Ou manuellement :

```bash
cd docker
docker-compose up -d
```

### 3. Importer les workflows

```bash
# Récupérer la clé API n8n depuis l'interface (Settings > API)
export N8N_API_KEY=votre_cle_api_n8n

# Importer tous les workflows
./scripts/import-workflows.sh

# Ou importer une catégorie spécifique
./scripts/import-workflows.sh ./workflows/01-leads
```

### 4. Configurer les credentials dans n8n

Dans n8n → Settings → Credentials, créez :

| Credential | Workflows concernés |
|------------|---------------------|
| PostgreSQL | Tous |
| Gmail OAuth2 | 1.1, 2.1, 4.1, 5.1, 5.2, 6.1, 8.1 |
| Google Calendar OAuth2 | 3.2, 3.3 |
| Google Drive OAuth2 | 3.1 |
| OpenAI API | 1.2, 2.2, 2.3, 4.3, 5.1–5.3, 6.2, 6.3, 7.1, 7.2, 8.1, 8.2 |
| Discord | Tous (notifications) |

---

## Catalogue détaillé

### 01 – Gestion des Leads

#### 1.1 – Centralisation des formulaires `P1`
Centralise les leads entrants (formulaire web, email, WhatsApp) vers CRM + Discord + email de confirmation.

**Déclencheurs :** Webhook POST `/lead-formulaire`, Gmail Trigger, Webhook WhatsApp  
**Actions :** Normalisation → PostgreSQL → CRM → Discord → Email confirmation

#### 1.2 – Qualification IA des prospects `P1`
Score et classe automatiquement les leads avec GPT-4o toutes les 15 minutes.

**Déclencheur :** Schedule (toutes les 15 min)  
**Sortie :** `{ type_client, budget_estime, priorite, probabilite_signature, score }`

---

### 02 – Gestion Commerciale

#### 2.1 – Relance automatique des devis `P1`
Envoie automatiquement J+3 et J+7 de relances pour les devis sans réponse.

**Déclencheur :** Schedule (lun-ven 8h)  
**Logique :** Relance 1 (courtois) → Relance 2 (dernière chance) → Notification commerciale

#### 2.2 – Génération automatique de devis `P2`
Génère un pré-devis structuré via IA depuis un formulaire, avec PDF et envoi pour validation.

**Déclencheur :** Webhook POST `/generer-devis`

#### 2.3 – Pipeline commercial IA `P2`
Analyse hebdomadaire du pipeline, TOP 5 prospects à contacter, estimation CA.

**Déclencheur :** Schedule (lundi 7h)

---

### 03 – Gestion Client

#### 3.1 – Création automatique des dossiers clients `P1`
Crée l'arborescence `Clients/Nom/Contrats|Factures|Documents|Photos` sur MinIO et Google Drive.

**Déclencheur :** Webhook POST `/nouveau-client`

#### 3.2 – Synchronisation CRM et agenda `P1`
Synchronise chaque RDV vers Google Calendar et envoie un rappel email J-1.

**Déclencheur :** Webhook POST `/nouveau-rdv`

#### 3.3 – Assistant de prise de rendez-vous
Propose des créneaux libres, permet la confirmation en un clic, crée l'événement Calendar.

**Déclencheurs :** Webhook `/demande-rdv` + `/confirmer-rdv`

---

### 04 – Gestion Administrative

#### 4.1 – Génération automatique de factures `P1`
Génère et envoie une facture PDF dès réception d'un paiement Stripe.

**Déclencheur :** Webhook Stripe `/stripe-webhook`

#### 4.2 – Gestion des impayés `P1`
3 niveaux de relance automatisée avec escalade Discord pour les cas critiques.

**Déclencheur :** Schedule (lun-ven 9h)

#### 4.3 – Génération documentaire IA `P2`
Génère contrats, courriers, comptes-rendus via GPT-4o avec export PDF.

**Déclencheur :** Webhook POST `/generer-document`  
**Types :** `contrat`, `compte-rendu`, `courrier`, `rapport`

---

### 05 – Intelligence Artificielle

#### 5.1 – Assistant de traitement des emails `P1`
Classe les emails entrants (prospect/facturation/SAV/urgent/spam) et déclenche les actions appropriées.

**Déclencheur :** Gmail Trigger (toutes les minutes)  
**Classification :** Prospect | Facturation | SAV | Urgent | Spam | Interne

#### 5.2 – Résumé de réunions `P2`
Transcrit un audio avec Whisper, génère un CR structuré (décisions + actions) et l'envoie par email.

**Déclencheur :** Webhook POST `/transcription-reunion` (upload audio)

#### 5.3 – Assistant de direction `P1`
Briefing matinal automatique : KPIs, RDV du jour, leads chauds, analyse IA → Email + Discord.

**Déclencheur :** Schedule (lun-ven 7h)

---

### 06 – Marketing

#### 6.1 – Gestion des avis clients `P3`
Envoie une demande d'avis 3 jours après une prestation, avec relance J+10 si pas d'avis.

#### 6.2 – Génération de contenu SEO `P3`
Génère un article de blog optimisé SEO à chaque projet terminé, publié en brouillon WordPress.

#### 6.3 – Analyse de la réputation `P3`
Consolide les avis Google + Trustpilot, analyse les sentiments et génère un rapport hebdo.

---

### 07 – Veille

#### 7.1 – Veille concurrentielle `P2`
Scrape les sites concurrents, analyse avec IA, envoie un rapport stratégique hebdomadaire.

**Déclencheur :** Schedule (mercredi 7h)

#### 7.2 – Veille technologique `P2`
Agrège GitHub Trending, Hacker News et Reddit, synthèse IA, envoi Discord + email.

**Déclencheur :** Schedule (vendredi 8h)

---

### 08 – Ressources Humaines

#### 8.1 – Tri de CV `–`
Score les CV reçus par email avec GPT-4o et envoie la réponse appropriée (positive/négative).

#### 8.2 – Onboarding collaborateurs `–`
Crée comptes Google Workspace + Discord + n8n, génère le kit d'accueil IA, annonce sur Discord.

---

## Variables d'environnement requises

Voir `docker/.env.example` pour la liste complète.

Variables minimales pour démarrer :

```bash
N8N_HOST=n8n.votre-domaine.fr
POSTGRES_PASSWORD=motdepasse_fort
REDIS_PASSWORD=motdepasse_fort
N8N_ENCRYPTION_KEY=cle_32_caracteres_min
OPENAI_API_KEY=sk-...
DISCORD_GUILD_ID=...
SMTP_USER=votre@email.com
SMTP_PASS=mot_de_passe_app
```

---

## Structure du projet

```
Nexum-Flow/
├── docker/
│   ├── docker-compose.yml      # Infrastructure complète
│   ├── .env.example            # Template variables d'environnement
│   ├── traefik/traefik.yml     # Configuration reverse proxy
│   └── postgres/init.sql       # Schéma de base de données
├── workflows/
│   ├── 01-leads/               # 2 workflows
│   ├── 02-commercial/          # 3 workflows
│   ├── 03-client/              # 3 workflows
│   ├── 04-administratif/       # 3 workflows
│   ├── 05-ia/                  # 3 workflows
│   ├── 06-marketing/           # 3 workflows
│   ├── 07-veille/              # 2 workflows (18 total)
│   └── 08-rh/                  # 2 workflows
└── scripts/
    ├── setup.sh                # Démarrage complet
    └── import-workflows.sh     # Import dans n8n
```

---

## Roadmap SaaS

| Pack | Workflows inclus | Cible |
|------|-----------------|-------|
| **Pack Lead Management** | 1.1 + 1.2 + 5.1 | PME commerciales |
| **Pack Commercial** | 2.1 + 2.2 + 2.3 | Équipes commerciales |
| **Pack Administratif** | 4.1 + 4.2 + 4.3 | TPE/PME |
| **Pack IA** | 5.1 + 5.2 + 5.3 | Direction |
| **Pack ERP** | Tous les workflows | Grandes PME |

---

## Licence

Propriétaire – Nexum Flow © 2024

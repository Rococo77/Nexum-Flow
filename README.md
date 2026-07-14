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
| 09 – Écoles post-bac | Candidatures, Admissions, Décrochage, Assistant scolarité, Stages | P1 / P2 |
| 10 – Vie quotidienne | Digest matinal, Budget, Courses/repas, Alertes prix, Routine santé, Veille perso, Admin, Journal, Sport, Sorties, Maison, OCR documents, Newsletters, Abonnements, Dates importantes, Garde-manger, Watchlist, Relevés foyer | perso |
| 11 – Pilotage | Suivi projet, Détection churn, Comptes-rendus, Veille appels d'offres | P1 / P2 |
| 12 – Ops | Gestion d'erreurs, Healthcheck, Purge RGPD, Sauvegarde workflows | P1 |
| 13 – Freelance | Briefing pré-RDV, Time-tracking, URSSAF, Portfolio, E-réputation | perso/pro |
| 14 – Verticaux | Artisans, Restaurant, Avis Google, Immobilier, Association | packs clients |

**Total : 65 workflows prêts à importer**

> Le module **09 – Écoles post-bac** est un pack vertical pour l'enseignement supérieur (universités, écoles d'ingénieurs/commerce, BTS) : il couvre le cycle complet candidature → admission → vie scolaire → stage.
>
> Le module **10 – Vie quotidienne** rassemble des automatisations personnelles (hors usage pro) : organisation, finances perso, santé, maison, gestion documentaire.
>
> Le module **11 – Pilotage** complète l'offre agence avec le suivi de production, la rétention client et la veille commerciale.

---

## Stack technique

```
n8n 2.12.3   – Orchestrateur de workflows (version épinglée, validée pour le catalogue)
PostgreSQL   – Base de données principale
Redis        – Queue d'exécution
FastAPI      – API métier (PDF, stockage, extraction)
MinIO        – Stockage de fichiers (S3-compatible)
Traefik      – Reverse proxy + SSL automatique
Mistral AI   – Modèles IA (mistral-large/small) via API compatible OpenAI
OpenAI       – Whisper (transcription audio, workflow 5.2 uniquement)
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
| Mistral AI (credential type "OpenAI", Base URL `https://api.mistral.ai/v1`) | 1.2, 2.2, 2.3, 4.3, 5.1, 5.3, 6.2, 6.3, 7.1, 7.2, 8.1, 8.2, 9.1, 9.3–9.6 |
| OpenAI API (Whisper) | 5.2 |
| Discord Bot API (token du bot + Guild ID) | Tous (notifications) |
| HTTP Basic Auth (WordPress, mot de passe d'application) | 6.2 |

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

#### 3.4 – Onboarding client complet `P1`
À la signature : crée le dossier de stockage, génère le contrat IA en PDF, envoie l'email de bienvenue avec le contrat, crée le canal Discord du projet et annonce le lancement. Le méta-workflow qui assemble les briques 3.1, 4.3 et Discord.

**Déclencheur :** Webhook POST `/onboarding-client` (`{ "client_id": "uuid", "projet": "..." }`)

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

#### 4.4 – Factures fournisseurs (OCR + échéancier) `P2`
Envoyez l'URL d'une facture fournisseur : OCR (OCR.space), extraction IA (fournisseur, montants, échéance, catégorie), enregistrement en base et notification compta.

**Déclencheur :** Webhook POST `/facture-fournisseur` (`{ "image_url": "https://..." }`)

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
Extrait le texte du CV joint (PDF via l'API d'extraction), le score avec l'IA et envoie la réponse appropriée (positive/négative). Sans pièce jointe, l'évaluation se fait sur le corps de l'email.

#### 8.2 – Onboarding collaborateurs `–`
Crée comptes Google Workspace + Discord + n8n, génère le kit d'accueil IA, annonce sur Discord.

---

### 09 – Écoles post-bac

Pack vertical pour les établissements d'enseignement supérieur. Couvre le parcours complet du candidat à l'étudiant.

#### 9.1 – Traitement automatisé des candidatures `P1`
Reçoit les candidatures, valide l'email, évalue le dossier avec l'IA (score, adéquation, recommandation) et enregistre + notifie le service admissions.

**Déclencheur :** Webhook POST `/candidature`  
**Sortie IA :** `{ score, adequation_formation, points_forts, points_vigilance, recommandation }`

#### 9.2 – Relance des dossiers incomplets `P1`
Relance automatiquement (jusqu'à 3 fois, espacées de 5 jours) les candidats dont le dossier est incomplet, en listant les pièces manquantes.

**Déclencheur :** Schedule (lun-ven 9h)

#### 9.3 – Décisions d'admission et convocations `P1`
Notifie la décision (admis / entretien / liste d'attente / refus) avec un email personnalisé, génère l'attestation PDF pour les admis et met à jour le statut.

**Déclencheur :** Webhook POST `/decision-admission`

#### 9.4 – Suivi de l'assiduité et alerte décrochage `P2`
Détecte les étudiants cumulant trop d'absences non justifiées, génère un message d'accompagnement bienveillant par IA et alerte le responsable pédagogique.

**Déclencheur :** Schedule (lundi 8h) · seuil configurable via `SEUIL_DECROCHAGE_HEURES`

#### 9.5 – Assistant IA du service scolarité `P2`
Répond automatiquement aux questions des étudiants (inscriptions, emploi du temps, bourses…). Escalade vers un conseiller humain si la confiance est faible ou si un dossier individuel est concerné.

**Déclencheur :** Webhook POST `/question-scolarite`  
**Sécurité :** sanitisation anti prompt-injection + seuil de confiance

#### 9.6 – Gestion des offres de stage et matching IA `P2`
Enregistre les offres déposées par les entreprises et identifie les étudiants les plus pertinents via l'IA, puis notifie le service stages.

**Déclencheur :** Webhook POST `/offre-stage`

---

### 10 – Vie quotidienne

Automatisations à usage personnel (hors contexte pro). Toutes les notifications partent vers `EMAIL_PERSO`.

#### 10.1 – Digest matinal personnalisé
Compile météo (wttr.in), Hacker News et l'actualité (RSS), puis génère un résumé motivant par IA, envoyé chaque matin à 7h.

**Déclencheur :** Schedule quotidien 7h

#### 10.2 – Suivi budget & alertes dépenses
Enregistre une dépense, cumule le mois par catégorie et alerte par email en cas de dépassement du budget mensuel.

**Déclencheur :** Webhook POST `/depense`

#### 10.3 – Liste de courses & planification repas
Ajoute des articles à la liste, puis l'IA propose un plan de repas hebdo et organise la liste par rayon.

**Déclencheur :** Webhook POST `/courses`

#### 10.4 – Alertes prix & suivi produits
Scrute quotidiennement les pages des produits surveillés et alerte dès qu'un prix baisse au-delà d'un seuil.

**Déclencheur :** Schedule quotidien 9h

#### 10.5 – Rappels santé & routine quotidienne
Messages adaptés au moment de la journée (matin, midi, après-midi, soir) + bilan hebdomadaire le dimanche.

**Déclencheur :** Schedule multi-horaires

#### 10.6 – Capture articles & bibliothèque personnelle
Envoyez une URL : extraction du texte, résumé + tags + points clés par IA, archivage dans une bibliothèque consultable.

**Déclencheur :** Webhook POST `/capture`

#### 10.7 – Assistant administratif perso
Analyse les emails récents, détecte les sujets administratifs (factures, relances, impôts, RDV médicaux…), extrait montant/échéance et notifie.

**Déclencheur :** Schedule quotidien 8h

#### 10.8 – Journal & suivi d'humeur
Saisie quotidienne d'une humeur (1-5) + note, avec réflexion bienveillante par IA. Bilan de tendance chaque dimanche.

**Déclencheur :** Webhook POST `/journal` + Schedule dimanche 20h

#### 10.9 – Suivi sportif & objectifs
Enregistre les séances (sans dépendance externe) et envoie un bilan hebdomadaire avec coaching IA vs objectif OMS.

**Déclencheur :** Webhook POST `/activite-sport` + Schedule dimanche 19h

#### 10.10 – Planificateur de sorties week-end
Récupère un agenda local (RSS) et l'IA recommande les sorties selon vos préférences, chaque jeudi.

**Déclencheur :** Schedule jeudi 18h

#### 10.11 – Alertes maison (météo, air, pollen)
Via Open-Meteo (sans clé) : alerte en cas de chaleur/gel/vent/pluie extrêmes, mauvaise qualité de l'air ou pollen élevé.

**Déclencheur :** Schedule quotidien 6h45

#### 10.12 – Capture & extraction de documents
Envoyez l'URL d'une photo de document : OCR (OCR.space) puis structuration IA (type, émetteur, montant, infos clés) et archivage.

**Déclencheur :** Webhook POST `/document`

#### 10.13 – Tri des newsletters
Chaque samedi, analyse les newsletters reçues sur 30 jours, identifie les expéditeurs les plus bruyants et envoie un bilan IA « à désabonner en priorité ».

**Déclencheur :** Schedule samedi 10h

#### 10.14 – Suivi des abonnements récurrents
Détecte dans les dépenses (10.2) les prélèvements identiques qui reviennent chaque mois, alerte sur les hausses de prix et estime le coût annuel des abonnements.

**Déclencheur :** Schedule le 2 du mois 8h30

#### 10.15 – Rappels de dates importantes
Anniversaires, renouvellements (CNI, assurance, contrôle technique…) : ajout par webhook, rappel automatique à J-30, J-7 et le jour J.

**Déclencheurs :** Webhook POST `/date-importante` + Schedule quotidien 8h

#### 10.16 – Garde-manger anti-gaspillage
Enregistrez vos produits et leur date de péremption : alerte 3 jours avant avec une recette IA qui utilise les ingrédients concernés.

**Déclencheurs :** Webhook POST `/garde-manger` + Schedule quotidien 18h

#### 10.17 – Bibliothèque lecture & watchlist
Capture de livres/films/séries (enrichissement Open Library pour les livres), puis bilan mensuel avec recommandations IA personnalisées.

**Déclencheurs :** Webhook POST `/watchlist` + Schedule le 1er du mois 19h

#### 10.18 – Relevés du foyer & tendance conso
Saisie des relevés (électricité, eau, gaz, km voiture), comparaison mensuelle et conseils de sobriété IA.

**Déclencheurs :** Webhook POST `/releve` + Schedule le 3 du mois 19h

---

### 11 – Pilotage

#### 11.1 – Suivi de projet & relances tâches `P1`
Détecte chaque matin les tâches en retard, bloquées ou à échéance proche et publie une synthèse IA actionnable sur Discord.

**Déclencheur :** Schedule jours ouvrés 8h30

#### 11.2 – Détection de churn client `P1`
Calcule un score de risque de départ par client (inactivité, impayés, réclamations) et propose un plan de rétention IA pour les clients à risque.

**Déclencheur :** Schedule lundi 7h

#### 11.3 – Compte-rendu de réunion & tâches `P2`
À partir de notes brutes, génère un compte-rendu structuré (résumé, décisions, tâches) envoyé par email et crée automatiquement les tâches en base.

**Déclencheur :** Webhook POST `/compte-rendu`

#### 11.4 – Veille appels d'offres `P2`
Interroge quotidiennement le BOAMP (open data, sans clé), déduplique, évalue la pertinence par IA et notifie les marchés intéressants.

**Déclencheur :** Schedule jours ouvrés 6h

---

### 12 – Ops

Supervision et hygiène de l'instance n8n elle-même.

#### 12.1 – Gestion centralisée des erreurs `P1`
Reçoit toutes les erreurs de workflows (Error Trigger), les historise en base (`workflow_errors`) et alerte les admins sur Discord avec le lien de l'exécution.

> ⚠️ **Après import** : ouvrez chaque workflow → Settings → *Error workflow* → sélectionnez « 12.1 – Gestion centralisée des erreurs ». Sans cela, les erreurs restent silencieuses.

#### 12.2 – Healthcheck de la stack `P1`
Vérifie FastAPI, MinIO et PostgreSQL toutes les 15 minutes (URLs internes Docker) et alerte Discord uniquement en cas de panne.

**Déclencheur :** Schedule `*/15 * * * *`

#### 12.3 – Purge RGPD mensuelle `P1`
Supprime chaque 1er du mois les données au-delà de la durée de rétention : leads perdus/spam, emails traités, questions scolarité, candidatures refusées, réservations restaurant, visites immobilières, dons anciens, membres inactifs et journaux techniques (erreurs, mentions, briefings). Durées configurables via `RETENTION_MOIS_*`, rapport Discord.

> ⚖️ Les dons/reçus fiscaux sont conservés au minimum 6 ans (obligation légale) : la purge applique `GREATEST(RETENTION_MOIS_DONS, 72)`. Les factures clients et fournisseurs ne sont jamais purgées (conservation comptable 10 ans).

**Déclencheur :** Schedule `0 3 1 * *`

#### 12.4 – Sauvegarde hebdomadaire des workflows `P2`
Exporte tous les workflows via l'API n8n et archive le JSON sur MinIO (`Backups/n8n/`), avec confirmation Discord.

**Déclencheur :** Schedule dimanche 4h · nécessite `N8N_API_KEY`

---

### 13 – Freelance / agence solo

Automatisations pour le dirigeant lui-même : préparation, temps, obligations, visibilité.

#### 13.1 – Briefing automatique avant RDV `P1`
1h avant chaque RDV Google Calendar avec un client connu du CRM, compile devis en cours, impayés, risque churn et échanges récents en une fiche briefing IA postée sur Discord. Anti-doublon via la table `briefings_envoyes`.

**Déclencheur :** Schedule toutes les 30 min (jours ouvrés 7h-19h)

#### 13.2 – Time-tracking passif par projet
Enregistre les activités par webhook (commits, messages, saisies manuelles) et envoie chaque vendredi un bilan des heures par projet avec analyse IA des dérives vs devis.

**Déclencheurs :** Webhook POST `/activite-projet` + Schedule vendredi 17h30

#### 13.3 – Rappel déclaration URSSAF avec CA pré-calculé `P1`
À J-10, J-3 et jour J de chaque échéance trimestrielle, calcule le CA encaissé de la période et les cotisations estimées (`TAUX_COTISATIONS_URSSAF`), puis envoie le récapitulatif par email. Montants indicatifs.

**Déclencheur :** Schedule quotidien 7h30 (n'envoie qu'aux échéances)

#### 13.4 – Portfolio auto-alimenté
À chaque projet livré : fiche cas-client rédigée par l'IA (besoin / solution / résultats), publiée en brouillon WordPress et archivée.

**Déclencheur :** Webhook POST `/portfolio`

#### 13.5 – Veille e-réputation personnelle
Surveille les mentions de `MARQUE_PERSO` sur Hacker News et Reddit (sans clé API), déduplique, trie par pertinence IA et alerte sur Discord.

**Déclencheur :** Schedule jours ouvrés 7h

---

### 14 – Packs verticaux

Workflows prêts à déployer chez des clients finaux, par métier.

#### 14.1 – Artisans : demande de devis par photo `P1`
Le prospect envoie description + photos du chantier : qualification IA (type de travaux, urgence, fourchette de prix, questions à poser), création du lead et notification commerciale. Accusé de réception automatique.

**Déclencheur :** Webhook POST `/demande-chantier`

#### 14.2 – Restaurant : réservations & rappel J-1
Confirmation immédiate par email, puis rappel automatique la veille à 18h (si la réservation est toujours active).

**Déclencheur :** Webhook POST `/reservation`

#### 14.3 – Réponse IA aux avis Google
Récupère chaque jour les nouveaux avis Google (Places API), rédige une réponse personnalisée (ton adapté aux avis négatifs) et la propose au gérant sur Discord, prête à coller dans Google Business.

**Déclencheur :** Schedule quotidien 10h · nécessite `GOOGLE_MAPS_API_KEY` + `GOOGLE_PLACE_ID`

#### 14.4 – Immobilier : relance après visite
Enregistre les visites, puis relance automatiquement l'acheteur à J+3 sans retour, avec copie à l'agent.

**Déclencheurs :** Webhook POST `/visite` + Schedule quotidien 9h30

#### 14.5 – Association : dons, reçus & cotisations
À chaque don/cotisation : reçu PDF généré et envoyé avec l'email de remerciement, adhésion prolongée d'un an. Relance mensuelle des adhésions expirées.

**Déclencheurs :** Webhook POST `/don` + Schedule le 1er du mois 9h

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
│   ├── 03-client/              # 4 workflows
│   ├── 04-administratif/       # 4 workflows
│   ├── 05-ia/                  # 3 workflows
│   ├── 06-marketing/           # 3 workflows
│   ├── 07-veille/              # 2 workflows
│   ├── 08-rh/                  # 2 workflows
│   ├── 09-education/           # 6 workflows
│   ├── 10-vie-quotidienne/     # 18 workflows
│   ├── 11-pilotage/            # 4 workflows
│   ├── 12-ops/                 # 4 workflows
│   ├── 13-freelance/           # 5 workflows
│   └── 14-verticaux/           # 5 workflows (65 total)
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
| **Pack Éducation** | 9.1 → 9.6 | Écoles & établissements post-bac |
| **Pack ERP** | Tous les workflows | Grandes PME |

---

## Licence

Propriétaire – Nexum Flow © 2024

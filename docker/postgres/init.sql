-- NEXUM FLOW - Initialisation de la base de données

-- Extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table des leads
CREATE TABLE IF NOT EXISTS leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source VARCHAR(50) NOT NULL,
    nom VARCHAR(255),
    prenom VARCHAR(255),
    email VARCHAR(255),
    telephone VARCHAR(50),
    entreprise VARCHAR(255),
    message TEXT,
    type_client VARCHAR(50),
    budget_estime VARCHAR(50),
    priorite VARCHAR(20) DEFAULT 'normale',
    probabilite_signature INTEGER DEFAULT 0,
    score INTEGER DEFAULT 0,
    statut VARCHAR(50) DEFAULT 'nouveau',
    commercial_assigne VARCHAR(255),
    crm_id VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des clients
CREATE TABLE IF NOT EXISTS clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id UUID REFERENCES leads(id),
    nom VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    telephone VARCHAR(50),
    entreprise VARCHAR(255),
    siret VARCHAR(20),
    adresse TEXT,
    dossier_path VARCHAR(500),
    crm_id VARCHAR(255),
    statut VARCHAR(50) DEFAULT 'actif',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des devis
CREATE TABLE IF NOT EXISTS devis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES clients(id),
    numero VARCHAR(50) UNIQUE,
    montant_ht DECIMAL(10,2),
    montant_ttc DECIMAL(10,2),
    statut VARCHAR(50) DEFAULT 'brouillon',
    date_envoi TIMESTAMPTZ,
    date_validite TIMESTAMPTZ,
    nb_relances INTEGER DEFAULT 0,
    derniere_relance TIMESTAMPTZ,
    pdf_path VARCHAR(500),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des factures
CREATE TABLE IF NOT EXISTS factures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES clients(id),
    devis_id UUID REFERENCES devis(id),
    numero VARCHAR(50) UNIQUE,
    montant_ht DECIMAL(10,2),
    montant_tva DECIMAL(10,2),
    montant_ttc DECIMAL(10,2),
    statut VARCHAR(50) DEFAULT 'en_attente',
    date_echeance DATE,
    date_paiement TIMESTAMPTZ,
    nb_relances INTEGER DEFAULT 0,
    derniere_relance TIMESTAMPTZ,
    pdf_path VARCHAR(500),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des rendez-vous
CREATE TABLE IF NOT EXISTS rendez_vous (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES clients(id),
    titre VARCHAR(255),
    description TEXT,
    date_debut TIMESTAMPTZ,
    date_fin TIMESTAMPTZ,
    lieu VARCHAR(255),
    type VARCHAR(50),
    statut VARCHAR(50) DEFAULT 'confirme',
    google_event_id VARCHAR(255),
    rappel_sms_envoye BOOLEAN DEFAULT FALSE,
    rappel_email_envoye BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des emails traités
CREATE TABLE IF NOT EXISTS emails_traites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id VARCHAR(255) UNIQUE,
    expediteur VARCHAR(255),
    sujet VARCHAR(500),
    classification VARCHAR(50),
    priorite VARCHAR(20),
    action_effectuee VARCHAR(100),
    ticket_id VARCHAR(255),
    traite_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des avis clients
CREATE TABLE IF NOT EXISTS avis_clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES clients(id),
    source VARCHAR(50),
    note INTEGER,
    commentaire TEXT,
    sentiment VARCHAR(20),
    publie BOOLEAN DEFAULT FALSE,
    date_demande TIMESTAMPTZ,
    date_reception TIMESTAMPTZ DEFAULT NOW()
);

-- Table des articles SEO générés
CREATE TABLE IF NOT EXISTS articles_seo (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES clients(id),
    projet_description TEXT,
    titre VARCHAR(500),
    contenu TEXT,
    mots_cles TEXT[],
    statut VARCHAR(50) DEFAULT 'brouillon',
    cms_id VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index sur les colonnes fréquemment utilisées
CREATE INDEX IF NOT EXISTS idx_leads_email ON leads(email);
CREATE INDEX IF NOT EXISTS idx_leads_statut ON leads(statut);
CREATE INDEX IF NOT EXISTS idx_devis_statut ON devis(statut);
CREATE INDEX IF NOT EXISTS idx_factures_statut ON factures(statut);
CREATE INDEX IF NOT EXISTS idx_factures_date_echeance ON factures(date_echeance);

-- Fonction de mise à jour automatique de updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_leads_updated_at BEFORE UPDATE ON leads FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trigger_clients_updated_at BEFORE UPDATE ON clients FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trigger_devis_updated_at BEFORE UPDATE ON devis FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trigger_factures_updated_at BEFORE UPDATE ON factures FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- 09 – Module Écoles post-bac (enseignement supérieur)
-- ============================================================

-- Table des candidatures
CREATE TABLE IF NOT EXISTS candidatures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nom VARCHAR(255),
    prenom VARCHAR(255),
    email VARCHAR(255),
    telephone VARCHAR(50),
    formation_visee VARCHAR(255),
    bac_serie VARCHAR(50),
    bac_mention VARCHAR(50),
    moyenne_generale DECIMAL(4,2),
    lettre_motivation TEXT,
    source VARCHAR(50) DEFAULT 'site',
    score INTEGER DEFAULT 0,
    recommandation VARCHAR(50),
    statut VARCHAR(50) DEFAULT 'recu',
    commentaire_ia TEXT,
    pieces_manquantes TEXT,
    nb_relances INTEGER DEFAULT 0,
    derniere_relance TIMESTAMPTZ,
    decision_notifiee_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des étudiants
CREATE TABLE IF NOT EXISTS etudiants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidature_id UUID REFERENCES candidatures(id),
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255),
    email VARCHAR(255),
    formation VARCHAR(255),
    promotion VARCHAR(50),
    competences TEXT,
    recherche_stage BOOLEAN DEFAULT FALSE,
    responsable_pedago_email VARCHAR(255),
    statut VARCHAR(50) DEFAULT 'actif',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des absences
CREATE TABLE IF NOT EXISTS absences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    etudiant_id UUID REFERENCES etudiants(id),
    date DATE NOT NULL,
    cours VARCHAR(255),
    duree_heures DECIMAL(4,1) DEFAULT 0,
    justifiee BOOLEAN DEFAULT FALSE,
    motif VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des questions au service scolarité
CREATE TABLE IF NOT EXISTS questions_scolarite (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    etudiant_email VARCHAR(255),
    question TEXT,
    reponse_ia TEXT,
    confiance DECIMAL(3,2),
    categorie VARCHAR(50),
    escalade BOOLEAN DEFAULT FALSE,
    traite_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des offres de stage / alternance
CREATE TABLE IF NOT EXISTS offres_stage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entreprise VARCHAR(255),
    contact_email VARCHAR(255),
    intitule VARCHAR(255),
    formation_cible VARCHAR(255),
    competences TEXT,
    type_contrat VARCHAR(50) DEFAULT 'stage',
    duree VARCHAR(100),
    description TEXT,
    statut VARCHAR(50) DEFAULT 'ouverte',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_candidatures_statut ON candidatures(statut);
CREATE INDEX IF NOT EXISTS idx_candidatures_email ON candidatures(email);
CREATE INDEX IF NOT EXISTS idx_etudiants_formation ON etudiants(formation);
CREATE INDEX IF NOT EXISTS idx_etudiants_statut ON etudiants(statut);
CREATE INDEX IF NOT EXISTS idx_absences_etudiant ON absences(etudiant_id);
CREATE INDEX IF NOT EXISTS idx_absences_date ON absences(date);

CREATE TRIGGER trigger_candidatures_updated_at BEFORE UPDATE ON candidatures FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trigger_etudiants_updated_at BEFORE UPDATE ON etudiants FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- 10 – Vie quotidienne
-- ============================================================

-- Budget personnel
CREATE TABLE IF NOT EXISTS depenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    montant DECIMAL(10,2) NOT NULL,
    categorie VARCHAR(100) DEFAULT 'autre',
    description VARCHAR(500),
    date DATE DEFAULT CURRENT_DATE,
    source VARCHAR(50) DEFAULT 'manuel',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Produits à surveiller (alertes prix)
CREATE TABLE IF NOT EXISTS produits_surveilles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nom VARCHAR(255) NOT NULL,
    url VARCHAR(1000) NOT NULL,
    prix_initial DECIMAL(10,2),
    prix_actuel DECIMAL(10,2),
    seuil_alerte DECIMAL(5,2) DEFAULT 10,
    derniere_verif TIMESTAMPTZ,
    actif BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bibliothèque personnelle d'articles
CREATE TABLE IF NOT EXISTS articles_personnels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    url VARCHAR(1000),
    titre VARCHAR(500),
    resume TEXT,
    points_cles TEXT[],
    tags TEXT[],
    contexte VARCHAR(500),
    lu BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Liste de courses
CREATE TABLE IF NOT EXISTS liste_courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    article VARCHAR(255) NOT NULL,
    categorie VARCHAR(100),
    quantite VARCHAR(100),
    achete BOOLEAN DEFAULT FALSE,
    semaine DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_depenses_date ON depenses(date);
CREATE INDEX IF NOT EXISTS idx_depenses_categorie ON depenses(categorie);
CREATE INDEX IF NOT EXISTS idx_produits_actif ON produits_surveilles(actif);
CREATE INDEX IF NOT EXISTS idx_articles_lu ON articles_personnels(lu);
CREATE INDEX IF NOT EXISTS idx_courses_semaine ON liste_courses(semaine);

-- Journal & suivi d'humeur (10.8)
CREATE TABLE IF NOT EXISTS journal_perso (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE DEFAULT CURRENT_DATE,
    humeur INTEGER CHECK (humeur BETWEEN 1 AND 5),
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Activités sportives (10.9)
CREATE TABLE IF NOT EXISTS activites_sport (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(50) DEFAULT 'autre',
    duree_min INTEGER NOT NULL,
    distance_km DECIMAL(6,2),
    ressenti VARCHAR(100),
    date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Échéances administratives détectées (10.7)
CREATE TABLE IF NOT EXISTS echeances_admin (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id VARCHAR(255) UNIQUE,
    type VARCHAR(50),
    libelle VARCHAR(255),
    montant DECIMAL(10,2),
    date_echeance DATE,
    action VARCHAR(300),
    expediteur VARCHAR(255),
    statut VARCHAR(50) DEFAULT 'a_traiter',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Documents capturés par OCR (10.12)
CREATE TABLE IF NOT EXISTS documents_perso (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(50),
    titre VARCHAR(255),
    emetteur VARCHAR(255),
    date_doc DATE,
    montant DECIMAL(10,2),
    infos_cles TEXT[],
    contenu_ocr TEXT,
    image_url VARCHAR(1000),
    a_conserver BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_journal_date ON journal_perso(date);
CREATE INDEX IF NOT EXISTS idx_sport_date ON activites_sport(date);
CREATE INDEX IF NOT EXISTS idx_echeances_date ON echeances_admin(date_echeance);
CREATE INDEX IF NOT EXISTS idx_documents_type ON documents_perso(type);

-- ============================================================
-- 11 – Pilotage (projets, churn, veille marchés)
-- ============================================================

-- Projets
CREATE TABLE IF NOT EXISTS projets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nom VARCHAR(255) NOT NULL,
    client VARCHAR(255),
    client_id UUID REFERENCES clients(id),
    deadline DATE,
    statut VARCHAR(50) DEFAULT 'en_cours',
    avancement INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tâches (11.1, alimentées aussi par 11.3)
CREATE TABLE IF NOT EXISTS taches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    projet_id UUID REFERENCES projets(id),
    titre VARCHAR(500) NOT NULL,
    assigne_email VARCHAR(255),
    deadline DATE,
    statut VARCHAR(50) DEFAULT 'a_faire',
    priorite VARCHAR(20),
    source VARCHAR(50) DEFAULT 'manuel',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Historique des scores de churn (11.2)
CREATE TABLE IF NOT EXISTS churn_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES clients(id),
    score_risque INTEGER,
    niveau VARCHAR(20),
    facteurs TEXT,
    diagnostic TEXT,
    actions TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Veille appels d'offres (11.4)
CREATE TABLE IF NOT EXISTS veille_marches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ref VARCHAR(255) UNIQUE,
    objet TEXT,
    organisme VARCHAR(300),
    date_parution DATE,
    date_limite DATE,
    url VARCHAR(1000),
    type_marche VARCHAR(255),
    pertinence VARCHAR(20),
    raison TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_taches_statut ON taches(statut);
CREATE INDEX IF NOT EXISTS idx_taches_projet ON taches(projet_id);
CREATE INDEX IF NOT EXISTS idx_taches_deadline ON taches(deadline);
CREATE INDEX IF NOT EXISTS idx_projets_statut ON projets(statut);
CREATE INDEX IF NOT EXISTS idx_churn_client ON churn_scores(client_id);
CREATE INDEX IF NOT EXISTS idx_veille_pertinence ON veille_marches(pertinence);

CREATE TRIGGER trigger_projets_updated_at BEFORE UPDATE ON projets FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trigger_taches_updated_at BEFORE UPDATE ON taches FOR EACH ROW EXECUTE FUNCTION update_updated_at();

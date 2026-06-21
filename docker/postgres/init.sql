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

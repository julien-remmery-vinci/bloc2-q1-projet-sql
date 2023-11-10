DROP SCHEMA IF EXISTS projet CASCADE ;
CREATE SCHEMA projet;

CREATE TABLE projet.etudiants(
    id_etudiant SERIAL PRIMARY KEY ,
    nom VARCHAR(50) NOT NULL CHECK ( nom != '' ),
    prenom VARCHAR(50) NOT NULL CHECK ( prenom != '' ),
    email VARCHAR(100) NOT NULL UNIQUE CHECK ( email != '' AND email LIKE '%@student.vinci.be' ),
    semestre VARCHAR(2) CHECK ( semestre IN ('Q1', 'Q2') ),
    mdp VARCHAR(100) NOT NULL ,
    nb_candidatures_attente INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE projet.entreprises(
    identifiant VARCHAR(3) PRIMARY KEY ,
    nom VARCHAR(50) NOT NULL ,
    adresse VARCHAR(100) NOT NULL ,
    mdp VARCHAR(100) NOT NULL ,
    email VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE projet.mots_cles(
    id_mot_cle SERIAL PRIMARY KEY ,
    mot_cle VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE projet.offres_de_stages(
    id_offre_stage SERIAL PRIMARY KEY ,
    etat VARCHAR(11) NOT NULL CHECK ( etat IN ('non validée', 'validée', 'attribuée', 'annulée') ) ,
    semestre VARCHAR(2) NOT NULL CHECK ( semestre IN ('Q1', 'Q2') ) ,
    description VARCHAR(100) NOT NULL ,
    id_entreprise INTEGER REFERENCES projet.entreprises(identifiant)  NOT NULL ,
    code_offre_stage VARCHAR(20) NOT NULL UNIQUE DEFAULT projet.entreprises.identifiant+id_offre_stage,
    nb_candidatures_attente INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE projet.mot_cle_stage(
    id_mot_cle INTEGER REFERENCES projet.mots_cles(id_mot_cle) NOT NULL ,
    id_offre_stage INTEGER REFERENCES projet.offres_de_stages(id_offre_stage) NOT NULL ,
    PRIMARY KEY (id_mot_cle, id_offre_stage)
);

CREATE TABLE projet.candidatures(
    etat VARCHAR(10) NOT NULL CHECK ( etat IN ('en attente', 'acceptée', 'refusée', 'annulée') ) ,
    motivations VARCHAR(100) NOT NULL ,
    id_offre_stage INTEGER REFERENCES projet.offres_de_stages(id_offre_stage),
    id_etudiant INTEGER REFERENCES projet.etudiants(id_etudiant),
    PRIMARY KEY (id_offre_stage, id_etudiant)
);

CREATE OR REPLACE FUNCTION encoderEtudiant(nomEtudiant VARCHAR(50), prenomEtudiant VARCHAR(50), emailEtudiant VARCHAR(100), semestreEtudiant VARCHAR(2), mdpEtudiant VARCHAR(100)) RETURNS INTEGER AS $$
DECLARE
    id INTEGER := 0;
BEGIN
    IF EXISTS(SELECT * FROM projet.etudiants e WHERE e.email = emailEtudiant)THEN
        RAISE 'email déjà utilisé';
    END IF;
    INSERT INTO projet.etudiants (nom, prenom, email, semestre, mdp) VALUES (nomEtudiant, prenomEtudiant, emailEtudiant, semestreEtudiant, mdpEtudiant) RETURNING id_etudiant INTO id;
    RETURN id;
END;
$$ LANGUAGE plpgsql;
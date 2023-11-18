DROP SCHEMA IF EXISTS projet CASCADE ;
CREATE SCHEMA projet;

CREATE TABLE projet.etudiants(
    id_etudiant SERIAL PRIMARY KEY ,
    nom VARCHAR(50) NOT NULL CHECK ( nom != '' )CHECK ( nom != '' ),
    prenom VARCHAR(50) NOT NULL CHECK ( prenom != '' )CHECK ( prenom != '' ),
    email VARCHAR(100) NOT NULL UNIQUE CHECK ( email != '' AND email LIKE '%@student.vinci.be' )CHECK ( email != '' AND email LIKE '%@student.vinci.be' ),
    semestre VARCHAR(2) CHECK ( semestre IN ('Q1', 'Q2') ),
    mdp VARCHAR(100) NOT NULL ,
    nb_candidatures_attente INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE projet.entreprises(
    identifiant_entreprise_entreprise VARCHAR(3) PRIMARY KEY ,
    nom VARCHAR(50) NOT NULL ,
    adresse VARCHAR(100) NOT NULL ,
    mdp VARCHAR(100) NOT NULL ,
    email VARCHAR(100) NOT NULL UNIQUE,
    nb_offres_stages INTEGER NOT NULL DEFAULT 0,
    nb_offres_stages INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE projet.mots_cles(
    id_mot_cle SERIAL PRIMARY KEY ,
    mot_cle VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE projet.offres_de_stages(
    id_offre_stage SERIAL PRIMARY KEY ,
    etat VARCHAR(11) NOT NULL DEFAULT 'non validée' DEFAULT 'non validée' CHECK ( etat IN ('non validée', 'validée', 'attribuée', 'annulée') ) ,
    semestre VARCHAR(2) NOT NULL CHECK ( semestre IN ('Q1', 'Q2') ) ,
    description VARCHAR(100) NOT NULL ,
    identifiant_entreprise VARCHAR(3) REFERENCES projet.entreprises(identifiant_entreprise)  NOT NULL ,
    code_offre_stage VARCHAR(20) NOT NULL UNIQUE,
    nb_candidatures_attente INTEGER NOT NULL DEFAULT 0,
    id_etudiant INTEGER REFERENCES projet.etudiants(id_etudiant) NULL
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

--TRIGGER ENTREPRISE
CREATE OR REPLACE FUNCTION projet.ajouterCodeOffre() RETURNS TRIGGER AS $$
DECLARE
    nb_offres varchar(20):='';
BEGIN
    SELECT cast(e.nb_offres_stages + 1 as varchar(20)) FROM projet.entreprises e INTO nb_offres;
        new.code_offre_stage = new.identifiant_entreprise || nb_offres;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER code_offre_trigger BEFORE INSERT ON projet.offres_de_stages FOR EACH ROW
EXECUTE PROCEDURE projet.ajouterCodeOffre();


CREATE OR REPLACE FUNCTION  projet.ajouterMotCleOffreTrigger() RETURNS TRIGGER AS $$
DECLARE

BEGIN
    IF((SELECT count(*) FROM projet.mot_cle_stage cs WHERE new.id_offre_stage = cs.id_offre_stage) = 3)
        THEN RAISE 'Il y a deja 3 mots clé pour cette offre de stage';
        END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER mot_cle_stage_trigger BEFORE INSERT ON projet.mot_cle_stage FOR EACH ROW
EXECUTE PROCEDURE projet.ajouterMotCleOffreTrigger();

--PARTIE PROFESSEUR
CREATE OR REPLACE FUNCTION projet.encoderEtudiant(nomEtudiant VARCHAR(50), prenomEtudiant VARCHAR(50), emailEtudiant VARCHAR(100), semestreEtudiant VARCHAR(2), mdpEtudiant VARCHAR(100)) RETURNS INTEGER AS $$
DECLARE
    id INTEGER := 0;
BEGIN
    INSERT INTO projet.etudiants (nom, prenom, email, semestre, mdp) VALUES (nomEtudiant, prenomEtudiant, emailEtudiant, semestreEtudiant, mdpEtudiant) RETURNING id_etudiant INTO id;
    RETURN id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.encoderEntreprise(nomEntreprise VARCHAR(50), adresseEntreprise VARCHAR(100),  emailEntreprise VARCHAR(100), identifiantEntreprise VARCHAR(3), mdpEntreprise VARCHAR(100)) RETURNS VARCHAR(3) AS $$
DECLARE

BEGIN
    INSERT INTO projet.entreprises (identifiant_entreprise, nom, adresse, mdp, email) VALUES (identifiantEntreprise, nomEntreprise, adresseEntreprise, emailEntreprise, mdpEntreprise);
    RETURN identifiantEntreprise;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.encoderMotcle(nouveauMotcle VARCHAR(20)) RETURNS VARCHAR(3) AS $$
DECLARE
    id INTEGER := 0;
BEGIN
    INSERT INTO projet.mots_cles (mot_cle) VALUES (nouveauMotcle) RETURNING id_mot_cle INTO id;
    RETURN id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.afficherOffresNonValidees() RETURNS SETOF RECORD AS $$
    DECLARE
        offre RECORD;
        sortie RECORD;
    BEGIN
        FOR offre IN SELECT * FROM projet.offres_de_stages os WHERE os.etat = 'non validée' LOOP
            SELECT offre.code_offre_stage, offre.semestre, e.nom, offre.description FROM projet.entreprises e INTO sortie;
            RETURN NEXT sortie;
        END LOOP;
    END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.validerOffre(code VARCHAR(20)) RETURNS BOOLEAN AS $$
    DECLARE
        offre RECORD;
    BEGIN
        IF NOT EXISTS(SELECT * FROM projet.offres_de_stages os WHERE os.code_offre_stage = code) THEN
            RAISE 'aucune offre éxistante avec ce code';
        END IF;
        SELECT * FROM projet.offres_de_stages os WHERE os.code_offre_stage = code INTO offre;
        IF offre.etat != 'non validée' THEN
            RAISE 'l offre entrée doit être non validée';
        END IF;
        UPDATE projet.offres_de_stages SET etat = 'validée' WHERE id_offre_stage = offre.id_offre_stage;
        RETURN TRUE;
    END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.afficherEtudiantsSansStage() RETURNS SETOF RECORD AS $$
    DECLARE
        etudiant RECORD;
        sortie RECORD;
    BEGIN
        FOR etudiant IN SELECT * FROM projet.etudiants LOOP
            IF NOT EXISTS(SELECT * FROM projet.candidatures c WHERE c.id_etudiant = etudiant.id_etudiant AND c.etat = 'acceptée') THEN
                SELECT etudiant.nom, etudiant.prenom, etudiant.email, etudiant.semestre, etudiant.nb_candidatures_attente INTO sortie;
                RETURN NEXT sortie;
            END IF;
        END LOOP;
    END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.afficherOffresAttribuees() RETURNS SETOF RECORD AS $$
    DECLARE
        offre RECORD;
        sortie RECORD;
    BEGIN
        FOR offre IN SELECT * FROM projet.offres_de_stages os WHERE os.etat = 'attribuée' LOOP
            SELECT offre.code_offre_stage, en.nom, et.nom, et.prenom FROM projet.entreprises en, projet.etudiants et INTO sortie;
            RETURN NEXT sortie;
        END LOOP;
    END;
    $$ LANGUAGE plpgsql;

--PARTIE ENTREPRISE
CREATE OR REPLACE FUNCTION projet.encoderOffreDeStage(_description VARCHAR(100), _semestre VARCHAR(2), _id_entreprise VARCHAR(3)) RETURNS INTEGER AS $$
DECLARE
    id INTEGER := 0;
    code_offre VARCHAR(20) := '';
BEGIN
    IF EXISTS(SELECT * FROM projet.entreprises e, projet.offres_de_stages o
                WHERE e.identifiant_entreprise = o.identifiant_entreprise AND e.identifiant_entreprise = _id_entreprise AND o.semestre = _semestre)
        THEN
        RAISE foreign_key_violation;
    END IF;
    INSERT INTO projet.offres_de_stages (semestre,description,identifiant_entreprise) VALUES (_semestre,_description,_id_entreprise)
        RETURNING id_offre_stage into id;
    return id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.voirSesOffres(identifiantEntreprise VARCHAR(3)) RETURNS SETOF RECORD AS $$
    DECLARE
        offre RECORD;
        sortie RECORD;
    BEGIN
        FOR offre IN SELECT * FROM projet.offres_de_stages os WHERE os.identifiant_entreprise = identifiantEntreprise LOOP
            IF offre.etat = 'attribuée' THEN
                SELECT offre.code_offre_stage, offre.description, offre.semestre, offre.etat, offre.nb_candidatures_attente, string_agg(e.nom, e.prenom) FROM projet.etudiants e GROUP BY offre.code_offre_stage, offre.description, offre.semestre, offre.etat, offre.nb_candidatures_attente INTO sortie;
                RETURN NEXT sortie;
                ELSE IF offre.etat = 'validée' THEN
                    SELECT offre.code_offre_stage, offre.description, offre.semestre, offre.etat, offre.nb_candidatures_attente, 'pas attribuée'::VARCHAR(100) INTO sortie;
                    RETURN NEXT sortie;
                end if;
            end if;
        END LOOP;
        RETURN;
    END;
    $$ LANGUAGE plpgsql;
--ENTREPRISE 5
CREATE OR REPLACE FUNCTION voirCandidatures(codeOffre VARCHAR(20), identifiantEntreprise VARCHAR(3)) RETURNS SETOF RECORD AS $$
    DECLARE
        candidature RECORD;
        sortie RECORD;
    BEGIN
        IF identifiantEntreprise != (SELECT os.identifiant_entreprise FROM projet.offres_de_stages os WHERE os.code_offre_stage = codeOffre)
            OR NOT EXISTS(SELECT * FROM projet.offres_de_stages WHERE code_offre_stage = codeOffre) THEN
            RAISE 'Il n''y a pas de candidatures pour cette offre ou vous n''avez pas d''offre ayant ce code';
        END IF;
        FOR candidature IN SELECT * FROM projet.candidatures c, projet.offres_de_stages os, projet.etudiants e
                                    WHERE c.id_offre_stage = os.id_offre_stage AND os.code_offre_stage = codeOffre AND e.id_etudiant = c.id_etudiant LOOP
            SELECT candidature.etat, candidature.nom, candidature.prenom, candidature.email, candidature.motivations INTO sortie;
            RETURN NEXT sortie;
        END LOOP;
        RETURN;
    END;
    $$ LANGUAGE plpgsql;
--ENTREPRISE 6
CREATE OR REPLACE FUNCTION selectionnerEtudiant(codeOffre VARCHAR(20), emailEtudiant VARCHAR(100), identifiantEntreprise VARCHAR(3)) RETURNS BOOLEAN AS $$
    DECLARE
        offre RECORD;
        etudiant RECORD;
    BEGIN
        IF identifiantEntreprise != (SELECT os.identifiant_entreprise FROM projet.offres_de_stages os WHERE os.code_offre_stage = codeOffre) THEN
            RAISE 'Il n''y a pas de candidatures pour cette offre ou vous n''avez pas d''offre ayant ce code';
        END IF;
        IF (SELECT os.etat FROM projet.offres_de_stages os WHERE code_offre_stage = codeOffre) != 'validée' THEN
            RAISE 'l''offre n''est pas dans l''etat validée';
        end if;
        IF (SELECT c.etat FROM projet.candidatures c, projet.offres_de_stages os, projet.etudiants e WHERE c.id_etudiant = e.id_etudiant AND c.id_offre_stage = os.id_offre_stage) != 'en attente' THEN
            RAISE 'l''offre n''est pas dans l''etat en attente';
        end if;
        SELECT * FROM projet.offres_de_stages WHERE code_offre_stage = codeOffre INTO offre;
        SELECT * FROM projet.etudiants WHERE email = emailEtudiant INTO etudiant;
        UPDATE projet.offres_de_stages SET etat = 'attribuée' WHERE code_offre_stage = codeOffre;
        UPDATE projet.candidatures set etat = 'acceptée' WHERE projet.etudiants.email = emailEtudiant;
        UPDATE projet.candidatures c SET etat = 'annulée' WHERE id_etudiant = etudiant.id_etudiant AND etat = 'en attente';
        UPDATE projet.candidatures c SET etat = 'refusée' WHERE c.id_offre_stage = offre.id_offre_stage AND etat = 'en attente';
        UPDATE projet.offres_de_stages os SET etat = 'annulée' WHERE os.identifiant_entreprise = offre.identifiant_entreprise AND os.semestre = offre.semestre AND etat = 'validée';
        UPDATE projet.candidatures c SET etat = 'refusée' WHERE c.etat = 'en attente' AND c.id_offre_stage = offre.id_offre_stage AND offre.identifiant_entreprise = identifiantEntreprise;
        RETURN TRUE;
    END;
    $$ LANGUAGE plpgsql;
--ENTREPRISE 7
CREATE OR REPLACE FUNCTION projet.annulerOffre(codeOffre VARCHAR(20), identifiantEntreprise VARCHAR(3)) RETURNS BOOLEAN AS $$
    DECLARE
        offre RECORD;
    BEGIN
        IF identifiantEntreprise != (SELECT os.identifiant_entreprise FROM projet.offres_de_stages os WHERE os.code_offre_stage = codeOffre) THEN
            RAISE 'Il n''y a pas de candidatures pour cette offre ou vous n''avez pas d''offre ayant ce code';
        END IF;
        IF (SELECT etat FROM projet.offres_de_stages WHERE code_offre_stage = codeOffre) != 'validée' THEN
            RAISE 'l''offre doit etre dans l''etat validée';
        end if;
        SELECT * FROM projet.offres_de_stages WHERE code_offre_stage = codeOffre INTO offre;
        UPDATE projet.candidatures c SET etat = 'annulée' WHERE c.id_offre_stage = offre.id_offre_stage;
    end;
    $$ LANGUAGE plpgsql;
    
    CREATE OR REPLACE FUNCTION projet.ajouterMotCleOffre(_mot_cle VARCHAR(20),_code_offre_stage VARCHAR(20)) RETURNS BOOLEAN AS $$
DECLARE
    offre RECORD;
    id_mot_cle INTEGER := 0;
    boolean BOOLEAN := TRUE;
BEGIN
    IF NOT EXISTS(SELECT * FROM projet.mots_cles m
                WHERE mot_cle = _mot_cle)
    THEN RAISE 'Le mot clé n''est pas dans la table mot clé';
    END IF;
    SELECT * FROM projet.mots_cles m
                WHERE mot_cle = _mot_cle INTO id_mot_cle;
    SELECT * from projet.offres_de_stages o WHERE o.code_offre_stage = _code_offre_stage INTO offre;
    IF EXISTS(SELECT * FROM projet.mot_cle_stage cs, projet.offres_de_stages o, projet.mots_cles m
                WHERE o.code_offre_stage = _code_offre_stage AND o.id_offre_stage = cs.id_offre_stage
                  AND cs.id_mot_cle = m.id_mot_cle AND (o.etat = 'attribuée' OR o.etat = 'annulée'))
        THEN
        RAISE 'Ne peut pas ajouter de mots clés';
    END IF;
    INSERT INTO projet.mot_cle_stage (id_mot_cle, id_offre_stage) VALUES (id_mot_cle,offre.id_offre_stage);
    RETURN boolean;
END;
$$ LANGUAGE plpgsql;
--PARTIE ETUDIANT
CREATE OR REPLACE FUNCTION  projet.afficherOffresStage(semestreEtudiant VARCHAR(2)) RETURNS SETOF RECORD AS $$
    DECLARE
        offre RECORD;
        sortie RECORD;
        mots_cle VARCHAR(60) := '';
        mot RECORD;
        sep VARCHAR;
    BEGIN
        for offre IN SELECT * FROM projet.offres_de_stages os WHERE os.etat = 'validée' AND os.semestre = semestreEtudiant LOOP
            for mot IN SELECT * FROM projet.mots_cles m, projet.mot_cle_stage cs,projet.offres_de_stages os WHERE cs.id_offre_stage = os.id_offre_stage AND m.id_mot_cle = cs.id_mot_cle LOOP
                IF mots_cle = '' THEN
                    mots_cle := mot.mot_cle;
                ELSE
                sep := ', ';
                mots_cle := mots_cle || sep || mot.mot_cle;
                end if;
            end loop;
            SELECT offre.code_offre_stage os,e.nom,e.adresse,offre.description,mots_cle
            FROM projet.entreprises e WHERE offre.identifiant_entreprise = e.identifiant_entreprise INTO sortie;
            RETURN NEXT sortie;
        END LOOP;
        return;
    END;
    $$ LANGUAGE plpgsql;
--ETUDIANT 2.
CREATE OR REPLACE FUNCTION  projet.rechercheStageParMotCle(mot_cle_cherche VARCHAR(60),semestreEtudiant VARCHAR(2)) RETURNS SETOF RECORD AS $$
    DECLARE
        offre RECORD;
        sortie RECORD;
        mots_cle VARCHAR(60) := '';
        mot RECORD;
        sep VARCHAR;
    BEGIN
        for offre IN SELECT * FROM projet.offres_de_stages os, projet.mot_cle_stage ms, projet.mots_cles mc WHERE mc.id_mot_cle = ms.id_mot_cle AND os.id_offre_stage = ms.id_offre_stage AND os.semestre = semestreEtudiant AND mc.mot_cle = mot_cle_cherche LOOP
            for mot IN SELECT * FROM projet.mots_cles m, projet.mot_cle_stage cs,projet.offres_de_stages os WHERE cs.id_offre_stage = os.id_offre_stage AND m.id_mot_cle = cs.id_mot_cle LOOP
                IF mots_cle = '' THEN
                    mots_cle := mot.mot_cle;
                ELSE
                sep := ', ';
                mots_cle := mots_cle || sep || mot.mot_cle;
                end if;
            end loop;
            SELECT offre.code_offre_stage os,e.nom,e.adresse,offre.description,mots_cle
            FROM projet.entreprises e WHERE offre.identifiant_entreprise = e.identifiant_entreprise INTO sortie;
            RETURN NEXT sortie;
        END LOOP;
        return;
    END;
    $$ LANGUAGE plpgsql;

--PROFESSEUR 1. Encoder un étudiant
SELECT projet.encoderEtudiant('Remmery', 'Julien', 'julien.remmery@student.vinci.be', 'Q1', 'test');
--PROFESSEUR 2. Encoder une entreprise
SELECT projet.encoderEntreprise('where2go', 'Rue des champions 1, Bruxelles', 'test@gmail.com', 'W2G', 'test');
--PROFESSEUR 3. Encoder un mot-clé que les entreprises pourront utiliser pour décrire leur stage
SELECT projet.encoderMotcle('Web');
SELECT projet.encoderMotcle('Java');
SELECT projet.encoderMotcle('JavaScript');
SELECT projet.encoderMotcle('SQL');
--ENTREPRISE 1. Encoder une offre de stage
SELECT projet.encoderOffreDeStage('Stage observation', 'Q1', 'W2G');
--ENTREPRISE 3. Ajouter un mot clé à une de ses offres de stage
SELECT projet.ajouterMotCleOffre('Web','W2G1');
SELECT projet.ajouterMotCleOffre('Java','W2G1');
SELECT projet.ajouterMotCleOffre('JavaScript','W2G1');
--SELECT projet.ajouterMotCleOffre('SQL','W2G1');
--PROFESSEUR 4. Voir les offres de stage dans l’état « non validée »
SELECT os.code_offre_stage, os.semestre, e.nom, os.description FROM projet.offres_de_stages os, projet.entreprises e WHERE os.identifiant_entreprise = e.identifiant_entreprise AND os.etat = 'non validée';
--PROFESSEUR 5. Valider une offre de stage en donnant son code
SELECT projet.valideroffre('W2G1');
--PROFESSEUR 6. Voir les offres de stage dans l’état « validée »
SELECT offre.code_offre_stage, offre.semestre, e.nom, offre.description FROM projet.entreprises e, projet.offres_de_stages offre WHERE offre.etat = 'validée';
--PROFESSEUR 7. Voir les étudiants qui n’ont pas de stage (pas de candidature à l’état « acceptée »).
SELECT e.nom, e.prenom, e.email, e.semestre, e.nb_candidatures_attente FROM projet.etudiants e
WHERE NOT EXISTS(SELECT * FROM projet.candidatures c WHERE c.id_etudiant = e.id_etudiant AND c.etat = 'acceptée');
--PROFESSEUR 8. Voir les offres de stage dans l’état « attribuée »
SELECT projet.afficherOffresAttribuees();
--ETUDIANT 1. Voir toutes les offres de stage dans l’état « validée » correspondant au semestre où l’étudiant fera son stage
SELECT * FROM projet.afficherOffresStage('Q1') AS (code_offre VARCHAR(20), nom_entreprise VARCHAR(50), adresse_entreprise VARCHAR(100), description_offre VARCHAR(100), mots_cles VARCHAR(60));
--ETUDIANT 2. Recherche d’une offre de stage par mot clé. (Meme semestre)
SELECT * FROM projet.rechercheStageParMotCle('Java','Q1') AS (code_offre VARCHAR(20), nom_entreprise VARCHAR(50), adresse_entreprise VARCHAR(100), description_offre VARCHAR(100), mots_cles VARCHAR(60));
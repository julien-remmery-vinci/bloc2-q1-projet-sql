DROP SCHEMA IF EXISTS projet CASCADE;
CREATE SCHEMA projet;

CREATE TABLE projet.etudiants
(
    id_etudiant             SERIAL PRIMARY KEY,
    nom                     VARCHAR(50)  NOT NULL CHECK ( nom != '' ),
    prenom                  VARCHAR(50)  NOT NULL CHECK ( prenom != '' ),
    email                   VARCHAR(100) NOT NULL UNIQUE CHECK ( email != '' AND email LIKE '%@student.vinci.be' ),
    semestre                VARCHAR(2) CHECK ( semestre IN ('Q1', 'Q2') ),
    mdp                     VARCHAR(100) NOT NULL,
    nb_candidatures_attente INTEGER      NOT NULL DEFAULT 0
);

CREATE TABLE projet.entreprises
(
    identifiant_entreprise VARCHAR(3) PRIMARY KEY,
    nom                    VARCHAR(50)  NOT NULL,
    adresse                VARCHAR(100) NOT NULL,
    mdp                    VARCHAR(100) NOT NULL,
    email                  VARCHAR(100) NOT NULL UNIQUE,
    nb_offres_stages       INTEGER      NOT NULL DEFAULT 0
);

CREATE TABLE projet.mots_cles
(
    id_mot_cle SERIAL PRIMARY KEY,
    mot_cle    VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE projet.offres_de_stages
(
    id_offre_stage          SERIAL PRIMARY KEY,
    etat                    VARCHAR(11)                                                       NOT NULL DEFAULT 'non validée' CHECK ( etat IN ('non validée', 'validée', 'attribuée', 'annulée') ),
    semestre                VARCHAR(2)                                                        NOT NULL CHECK ( semestre IN ('Q1', 'Q2') ),
    description             VARCHAR(100)                                                      NOT NULL,
    identifiant_entreprise  VARCHAR(3) REFERENCES projet.entreprises (identifiant_entreprise) NOT NULL,
    code_offre_stage        VARCHAR(20)                                                       NOT NULL UNIQUE,
    nb_candidatures_attente INTEGER                                                           NOT NULL DEFAULT 0,
    id_etudiant             INTEGER REFERENCES projet.etudiants (id_etudiant)                 NULL
);

CREATE TABLE projet.mot_cle_stage
(
    id_mot_cle     INTEGER REFERENCES projet.mots_cles (id_mot_cle)            NOT NULL,
    id_offre_stage INTEGER REFERENCES projet.offres_de_stages (id_offre_stage) NOT NULL,
    PRIMARY KEY (id_mot_cle, id_offre_stage)
);

CREATE TABLE projet.candidatures
(
    etat           VARCHAR(10)  NOT NULL DEFAULT 'en attente' CHECK ( etat IN ('en attente', 'acceptée', 'refusée', 'annulée') ),
    motivations    VARCHAR(100) NOT NULL,
    id_offre_stage INTEGER REFERENCES projet.offres_de_stages (id_offre_stage),
    id_etudiant    INTEGER REFERENCES projet.etudiants (id_etudiant),
    PRIMARY KEY (id_offre_stage, id_etudiant)
);

--TRIGGER ENTREPRISE
-- CREATE OR REPLACE FUNCTION projet.augmenterNbOffres() RETURNS TRIGGER AS
-- $$
-- DECLARE
--     nb_offres INTEGER;
-- BEGIN
--     SELECT e.nb_offres_stages
--     FROM projet.entreprises e
--     WHERE e.identifiant_entreprise = NEW.identifiant_entreprise
--     INTO nb_offres;
--     UPDATE projet.entreprises
--     SET nb_offres_stages = nb_offres_stages + 1
--     WHERE identifiant_entreprise = NEW.identifiant_entreprise;
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;
--
-- CREATE TRIGGER augmenter_nb_offres_trigger
--     BEFORE INSERT
--     ON projet.offres_de_stages
--     FOR EACH ROW
-- EXECUTE PROCEDURE projet.augmenterNbOffres();


CREATE OR REPLACE FUNCTION projet.ajouterCodeOffre() RETURNS TRIGGER AS
$$
DECLARE
    nb_offres INTEGER := 0;
    oldNbOffre INTEGER := 0;
BEGIN
    IF EXISTS(SELECT o.id_offre_stage
              FROM projet.entreprises e,
                   projet.offres_de_stages o
              WHERE e.identifiant_entreprise = o.identifiant_entreprise
                AND e.identifiant_entreprise = new.identifiant_entreprise
                AND o.semestre = new.semestre
                AND o.etat = 'attribuée')
    THEN
        RAISE 'Il y a déjà une offre de stage attribuée pour ce semestre';
    END IF;

    SELECT e.nb_offres_stages
    FROM projet.entreprises e
    WHERE e.identifiant_entreprise = NEW.identifiant_entreprise
    INTO oldNbOffre;
    UPDATE projet.entreprises
    SET nb_offres_stages = nb_offres_stages + 1
    WHERE identifiant_entreprise = NEW.identifiant_entreprise;

    SELECT e.nb_offres_stages
    FROM projet.entreprises e
    WHERE e.identifiant_entreprise = NEW.identifiant_entreprise
    INTO nb_offres;
    new.code_offre_stage = new.identifiant_entreprise || CAST(nb_offres AS VARCHAR);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER code_offre_trigger
    BEFORE INSERT
    ON projet.offres_de_stages
    FOR EACH ROW
EXECUTE PROCEDURE projet.ajouterCodeOffre();

CREATE OR REPLACE FUNCTION projet.ajouterMotCleOffreTrigger() RETURNS TRIGGER AS
$$
DECLARE

BEGIN
    IF ((SELECT count(cs.id_offre_stage) FROM projet.mot_cle_stage cs WHERE new.id_offre_stage = cs.id_offre_stage) = 3)
    THEN
        RAISE 'Il y a deja 3 mots clé pour cette offre de stage';
    END IF;
    IF EXISTS(SELECT cs.id_offre_stage
              FROM projet.mot_cle_stage cs,
                   projet.offres_de_stages o,
                   projet.mots_cles m
              WHERE o.id_offre_stage = new.id_offre_stage
                AND o.id_offre_stage = cs.id_offre_stage
                AND cs.id_mot_cle = m.id_mot_cle
                AND (o.etat = 'attribuée' OR o.etat = 'annulée'))
    THEN
        RAISE 'Ne peut pas ajouter de mots clés';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER mot_cle_stage_trigger
    BEFORE INSERT
    ON projet.mot_cle_stage
    FOR EACH ROW
EXECUTE PROCEDURE projet.ajouterMotCleOffreTrigger();

-- CREATE OR REPLACE FUNCTION projet.annulerOffreTrigger() RETURNS TRIGGER AS
-- $$
-- DECLARE
--
-- BEGIN
--     IF new.identifiant_entreprise != (SELECT os.identifiant_entreprise
--                                       FROM projet.offres_de_stages os
--                                       WHERE os.code_offre_stage = new.code_offre_stage) THEN
--         RAISE 'Il n''y a pas de candidatures pour cette offre ou vous n''avez pas d''offre ayant ce code';
--     END IF;
--     IF (SELECT etat FROM projet.offres_de_stages WHERE code_offre_stage = new.code_offre_stage) != 'validée' THEN
--         RAISE 'l''offre doit etre dans l''etat validée';
--     end if;
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

--PARTIE PROFESSEUR
--1. Encoder un étudiant
CREATE OR REPLACE FUNCTION projet.encoderEtudiant(nomEtudiant VARCHAR(50), prenomEtudiant VARCHAR(50),
                                                  emailEtudiant VARCHAR(100), semestreEtudiant VARCHAR(2),
                                                  mdpEtudiant VARCHAR(100)) RETURNS INTEGER AS
$$
DECLARE
    id INTEGER := 0;
BEGIN
    INSERT INTO projet.etudiants (nom, prenom, email, semestre, mdp)
    VALUES (nomEtudiant, prenomEtudiant, emailEtudiant, semestreEtudiant, mdpEtudiant)
    RETURNING id_etudiant INTO id;
    RETURN id;
END;
$$ LANGUAGE plpgsql;

--2. Encoder une entreprise
CREATE OR REPLACE FUNCTION projet.encoderEntreprise(nomEntreprise VARCHAR(50), adresseEntreprise VARCHAR(100),
                                                    emailEntreprise VARCHAR(100), identifiantEntreprise VARCHAR(3),
                                                    mdpEntreprise VARCHAR(100)) RETURNS VARCHAR(3) AS
$$
DECLARE

BEGIN
    INSERT INTO projet.entreprises (identifiant_entreprise, nom, adresse, mdp, email)
    VALUES (identifiantEntreprise, nomEntreprise, adresseEntreprise, mdpEntreprise, emailEntreprise);
    RETURN identifiantEntreprise;
END;
$$ LANGUAGE plpgsql;

--3. Encoder un mot-clé
CREATE OR REPLACE FUNCTION projet.encoderMotcle(nouveauMotcle VARCHAR(20)) RETURNS VARCHAR(3) AS
$$
DECLARE
    id INTEGER := 0;
BEGIN
    INSERT INTO projet.mots_cles (mot_cle) VALUES (nouveauMotcle) RETURNING id_mot_cle INTO id;
    RETURN id;
END;
$$ LANGUAGE plpgsql;

--PROFESSEUR 4. Voir les offres de stage dans l’état « non validée »
CREATE OR REPLACE VIEW projet.voirOffresNonValidees (code_offre_stage, semestre, nom, desciption) AS
SELECT os.code_offre_stage, os.semestre, e.nom, os.description
FROM projet.offres_de_stages os,
     projet.entreprises e
WHERE os.identifiant_entreprise = e.identifiant_entreprise
  AND os.etat = 'non validée';

CREATE OR REPLACE FUNCTION projet.validerOffreTrigger() RETURNS TRIGGER AS
$$
DECLARE

BEGIN
    IF OLD.etat != 'non validée' AND NEW.etat != 'attribuée' AND NEW.etat != 'annulée' THEN
        RAISE 'l offre entrée doit être non validée';
    END IF;
    IF NEW.etat = 'annulée' AND OLD.etat = 'annulée' THEN
        RAISE 'l''offre est deja annulée';
    end if;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER valider_offre_trigger
    BEFORE UPDATE
    ON projet.offres_de_stages
    FOR EACH ROW
EXECUTE PROCEDURE projet.validerOffreTrigger();

--5. Valider une offre de stage en donnant son code
CREATE OR REPLACE FUNCTION projet.validerOffre(code VARCHAR(20)) RETURNS VOID AS
$$
DECLARE

BEGIN
    IF NOT EXISTS(SELECT os.id_offre_stage
                  FROM projet.offres_de_stages os
                  WHERE os.code_offre_stage = code) THEN
        RAISE 'aucune offre éxistante avec ce code';
    END IF;
    UPDATE projet.offres_de_stages SET etat = 'validée' WHERE code_offre_stage = code;
END;
$$ LANGUAGE plpgsql;

--PROFESSEUR 6. Voir les offres de stage dans l’état « validée
CREATE OR REPLACE VIEW projet.voirOffresValidees (code_offre_stage, semestre, nom, description) AS
SELECT offre.code_offre_stage, offre.semestre, e.nom, offre.description
FROM projet.entreprises e,
     projet.offres_de_stages offre
WHERE offre.etat = 'validée'
  AND offre.identifiant_entreprise = e.identifiant_entreprise;

--PROFESSEUR 7. Voir les étudiants qui n’ont pas de stage (pas de candidature à l’état « acceptée »).
CREATE OR REPLACE VIEW projet.voirEtudiantsSansStage (nom, prenom, email, semestre, nb_candidatures_attente) AS
SELECT e.nom, e.prenom, e.email, e.semestre, e.nb_candidatures_attente
FROM projet.etudiants e
WHERE NOT EXISTS(SELECT id_offre_stage FROM projet.candidatures c WHERE c.id_etudiant = e.id_etudiant AND c.etat = 'acceptée');

--8. Voir les offres de stage dans l’état « attribuée »
CREATE OR REPLACE FUNCTION projet.afficherOffresAttribuees() RETURNS SETOF RECORD AS
$$
DECLARE
    codeOffre VARCHAR(20);
    sortie RECORD;
BEGIN
    FOR codeOffre IN SELECT code_offre_stage FROM projet.offres_de_stages os WHERE os.etat = 'attribuée'
        LOOP
            SELECT codeOffre, en.nom, et.nom, et.prenom
            FROM projet.entreprises en,
                 projet.etudiants et
            INTO sortie;
            RETURN NEXT sortie;
        END LOOP;
END;
$$ LANGUAGE plpgsql;

--PARTIE ENTREPRISE
--1 Encoder une offre de stage
CREATE OR REPLACE FUNCTION projet.encoderOffreDeStage(_description VARCHAR(100), _semestre VARCHAR(2),
                                                      _id_entreprise VARCHAR(3)) RETURNS INTEGER AS
$$
DECLARE
    id INTEGER := 0;
BEGIN
    INSERT INTO projet.offres_de_stages (semestre, description, identifiant_entreprise)
    VALUES (_semestre, _description, _id_entreprise)
    RETURNING id_offre_stage into id;
    return id;
END;
$$ LANGUAGE plpgsql;

--3 Ajouter un mot-clé
CREATE OR REPLACE FUNCTION projet.ajouterMotCleOffre(_mot_cle VARCHAR(20), _code_offre_stage VARCHAR(20),
                                                     _id_entreprise VARCHAR(3)) RETURNS VOID AS
$$
DECLARE
    idOffre INTEGER := 0;
    idMot INTEGER := 0;
BEGIN
    IF NOT EXISTS (SELECT id_offre_stage
                   FROM projet.offres_de_stages o
                   WHERE o.identifiant_entreprise = _id_entreprise
                     AND o.code_offre_stage = _code_offre_stage) THEN
        RAISE 'Ne peut pas ajouter un mot clé pour une autre entreprise';
    END IF;
    SELECT m.id_mot_cle
    FROM projet.mots_cles m
    WHERE mot_cle = _mot_cle
    INTO idMot;
    SELECT id_offre_stage
    from projet.offres_de_stages
    WHERE code_offre_stage = _code_offre_stage
    INTO idOffre;
    INSERT INTO projet.mot_cle_stage (id_mot_cle, id_offre_stage) VALUES (idMot, idOffre);
END;
$$ LANGUAGE plpgsql;


--4 Voir ses offres de stages
CREATE OR REPLACE FUNCTION projet.voirSesOffres(identifiantEntreprise VARCHAR(3)) RETURNS SETOF RECORD AS
$$
DECLARE
    offre  RECORD;
    sortie RECORD;
BEGIN
    FOR offre IN SELECT code_offre_stage, description, semestre, etat, id_offre_stage, nb_candidatures_attente FROM projet.offres_de_stages os WHERE os.identifiant_entreprise = identifiantEntreprise ORDER BY code_offre_stage
        LOOP
            IF offre.etat = 'attribuée' THEN
                SELECT offre.code_offre_stage,
                       offre.description,
                       offre.semestre,
                       offre.etat,
                       os.nb_candidatures_attente,
                       concat(e.nom, ' ', e.prenom)::VARCHAR(100)
                FROM projet.etudiants e,
                     projet.offres_de_stages os
                WHERE offre.id_offre_stage = os.id_offre_stage
                  AND os.id_etudiant = e.id_etudiant
                INTO sortie;
                RETURN NEXT sortie;
            ELSE
                SELECT offre.code_offre_stage,
                           offre.description,
                           offre.semestre,
                           offre.etat,
                           offre.nb_candidatures_attente,
                           'pas attribuée'::VARCHAR(100)
                    INTO sortie;
                    RETURN NEXT sortie;
            end if;
        END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;

--ENTREPRISE 5
CREATE OR REPLACE FUNCTION projet.voirCandidatures(codeOffre VARCHAR(20), idEntreprise VARCHAR(3)) RETURNS SETOF RECORD AS
$$
DECLARE
    candidature RECORD;
    sortie      RECORD;
BEGIN
    IF idEntreprise != (SELECT identifiant_entreprise FROM projet.offres_de_stages WHERE code_offre_stage = codeOffre) THEN
        RAISE 'Il n''y a pas de candidatures pour cette offre ou vous n''avez pas d''offre ayant ce code';
    end if;
    FOR candidature IN SELECT c.etat, e.nom, e.prenom, e.email, c.motivations
                       FROM projet.candidatures c,
                            projet.offres_de_stages os,
                            projet.etudiants e
                       WHERE c.id_offre_stage = os.id_offre_stage
                         AND os.code_offre_stage = codeOffre
                         AND e.id_etudiant = c.id_etudiant
        LOOP
            SELECT candidature.etat, candidature.nom, candidature.prenom, candidature.email, candidature.motivations
            INTO sortie;
            RETURN NEXT sortie;
        END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;

--ENTREPRISE 6
CREATE OR REPLACE FUNCTION projet.selectionnerEtudiant(codeOffre VARCHAR(20), emailEtudiant VARCHAR(100),
                                                       identifiantEntreprise VARCHAR(3)) RETURNS BOOLEAN AS
$$
DECLARE
    offre    RECORD;
    etudiant INTEGER := 0;
BEGIN
    SELECT id_offre_stage, identifiant_entreprise, semestre FROM projet.offres_de_stages WHERE code_offre_stage = codeOffre INTO offre;
    SELECT id_etudiant FROM projet.etudiants WHERE email = emailEtudiant INTO etudiant;
    IF identifiantEntreprise !=
       (SELECT os.identifiant_entreprise FROM projet.offres_de_stages os WHERE os.code_offre_stage = codeOffre) THEN
        RAISE 'Il n''y a pas de candidatures pour cette offre ou vous n''avez pas d''offre ayant ce code';
    END IF;
    IF (SELECT c.etat
        FROM projet.candidatures c
        WHERE c.id_etudiant = etudiant
          AND c.id_offre_stage = offre.id_offre_stage) != 'en attente' THEN
        RAISE 'la candidature n''est pas dans l''etat en attente';
    end if;
    IF (SELECT etat
        FROM projet.offres_de_stages
        WHERE code_offre_stage = codeOffre) = 'non validée' THEN
        RAISE 'L''offre doit etre validée';
    end if;
    UPDATE projet.offres_de_stages
    SET etat        = 'attribuée',
        id_etudiant = etudiant
    WHERE code_offre_stage = codeOffre;
    UPDATE projet.candidatures c
    set etat = 'acceptée'
    WHERE c.id_etudiant = etudiant
      AND c.id_offre_stage = offre.id_offre_stage;
    UPDATE projet.candidatures c SET etat = 'annulée' WHERE id_etudiant = etudiant AND etat = 'en attente';
    UPDATE projet.candidatures c
    SET etat = 'refusée'
    WHERE c.id_offre_stage = offre.id_offre_stage
      AND etat = 'en attente';
    UPDATE projet.offres_de_stages os
    SET etat = 'annulée'
    WHERE os.identifiant_entreprise = offre.identifiant_entreprise
      AND os.semestre = offre.semestre
      AND (etat = 'validée' OR etat = 'non validée');
    UPDATE projet.candidatures c
    SET etat = 'refusée'
    WHERE c.etat = 'en attente'
      AND c.id_offre_stage = offre.id_offre_stage
      AND offre.identifiant_entreprise = identifiantEntreprise;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
--ENTREPRISE 7

CREATE OR REPLACE FUNCTION projet.annulerOffre(codeOffre VARCHAR(20), _identifiant_entreprise VARCHAR(3)) RETURNS VOID AS
$$
DECLARE
    idOffre INTEGER := 0;
BEGIN
    IF _identifiant_entreprise !=
       (SELECT identifiant_entreprise from projet.offres_de_stages WHERE code_offre_stage = codeOffre)
    THEN
        RAISE 'L''offre n''est de cette entreprise';
    END IF;
    IF NOT EXISTS(SELECT code_offre_stage FROM projet.offres_de_stages WHERE code_offre_stage = codeOffre) THEN
        RAISE 'l''offre n''existe pas';
    end if;
    SELECT id_offre_stage FROM projet.offres_de_stages WHERE code_offre_stage = codeOffre INTO idOffre;
    UPDATE projet.offres_de_stages c SET etat = 'annulée' WHERE c.id_offre_stage = idOffre;
    UPDATE projet.candidatures c SET etat = 'refusée' WHERE c.id_offre_stage = idOffre;
end;
$$ LANGUAGE plpgsql;
--PARTIE ETUDIANT
CREATE OR REPLACE FUNCTION projet.afficherOffresStage(semestreEtudiant VARCHAR(2)) RETURNS SETOF RECORD AS
$$
DECLARE
    offre    RECORD;
    sortie   RECORD;
    mots_cle VARCHAR(60) := '';
    mot      VARCHAR(20);
    sep      VARCHAR;
BEGIN
    for offre IN SELECT code_offre_stage, description, identifiant_entreprise, id_offre_stage FROM projet.offres_de_stages os WHERE os.etat = 'validée' AND os.semestre = semestreEtudiant
        LOOP
            for mot IN SELECT mot_cle
                       FROM projet.mots_cles m,
                            projet.mot_cle_stage cs
                       WHERE cs.id_offre_stage = offre.id_offre_stage
                         AND m.id_mot_cle = cs.id_mot_cle
                LOOP
                    IF mots_cle = '' THEN
                        mots_cle := mot;
                    ELSE
                        sep := ', ';
                        mots_cle := mots_cle || sep || mot;
                    end if;
                end loop;
            SELECT offre.code_offre_stage os, e.nom, e.adresse, offre.description, mots_cle
            FROM projet.entreprises e
            WHERE offre.identifiant_entreprise = e.identifiant_entreprise
            INTO sortie;
            RETURN NEXT sortie;
        END LOOP;
    return;
END;
$$ LANGUAGE plpgsql;
--ETUDIANT 2.
CREATE OR REPLACE FUNCTION projet.rechercheStageParMotCle(mot_cle_cherche VARCHAR(60), semestreEtudiant VARCHAR(2)) RETURNS SETOF RECORD AS
$$
DECLARE
    offre    RECORD;
    sortie   RECORD;
    mots_cle VARCHAR(60) := '';
    mot      VARCHAR(20);
    sep      VARCHAR;
BEGIN
    for offre IN SELECT ms.id_offre_stage, code_offre_stage, description, identifiant_entreprise
                 FROM projet.offres_de_stages os,
                      projet.mot_cle_stage ms,
                      projet.mots_cles mc
                 WHERE mc.id_mot_cle = ms.id_mot_cle
                   AND os.id_offre_stage = ms.id_offre_stage
                   AND os.semestre = semestreEtudiant
                   AND mc.mot_cle = mot_cle_cherche
                   AND os.etat = 'validée'
        LOOP
            for mot IN SELECT mot_cle
                       FROM projet.mots_cles m,
                            projet.mot_cle_stage cs
                       WHERE cs.id_offre_stage = offre.id_offre_stage
                         AND m.id_mot_cle = cs.id_mot_cle
                LOOP
                    IF mots_cle = '' THEN
                        mots_cle := mot;
                    ELSE
                        sep := ', ';
                        mots_cle := mots_cle || sep || mot;
                    end if;
                end loop;
            SELECT offre.code_offre_stage os, e.nom, e.adresse, offre.description, mots_cle
            FROM projet.entreprises e
            WHERE offre.identifiant_entreprise = e.identifiant_entreprise
            INTO sortie;
            RETURN NEXT sortie;
        END LOOP;
    return;
END;
$$ LANGUAGE plpgsql;

--ETUDIANT 3.
--3. Poser sa candidature. Pour cela, il doit donner le code de l’offre de stage et donner ses
--motivations sous format textuel. Il ne peut poser de candidature s’il a déjà une
-- acceptée, s’il a déjà posé sa candidature pour cette offre, si l’offre n’est
--pas dans l’état validée ou si l’offre ne correspond pas au bon semestre.
CREATE OR REPLACE FUNCTION projet.poserCandidatureTrigger() RETURNS TRIGGER AS
$$
DECLARE

BEGIN
    IF EXISTS (SELECT ca.id_offre_stage
               FROM projet.candidatures ca
               WHERE ca.etat = 'acceptée'
                 AND ca.id_etudiant = NEW.id_etudiant)
    THEN
        RAISE 'L ''etudiant a dejà une offre de stage acceptée';
    END IF;
    IF EXISTS (SELECT ca.id_offre_stage
               FROM projet.candidatures ca
               WHERE ca.id_offre_stage = NEW.id_offre_stage
                 AND ca.id_etudiant = NEW.id_etudiant)
    THEN
        RAISE 'L ''etudiant a dejà postulé pour l''offre de stage';
    END IF;
    IF EXISTS (SELECT of.id_offre_stage
               FROM projet.offres_de_stages of,
                    projet.etudiants et
               WHERE of.id_offre_stage = NEW.id_offre_stage
                 AND et.id_etudiant = NEW.id_etudiant
                 AND (of.etat = 'non validée' OR of.semestre != et.semestre))
    THEN
        RAISE 'Etat non validée ou mauvais semestre';
    END IF;
    IF EXISTS(SELECT id_offre_stage
              FROM projet.offres_de_stages
              WHERE id_offre_stage = NEW.id_offre_stage AND etat = 'annulée') THEN
        RAISE 'L''offre est dans l''etat annulée';
    end if;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER checkCandidature
    BEFORE INSERT
    ON projet.candidatures
    FOR EACH ROW
EXECUTE PROCEDURE projet.poserCandidatureTrigger();

CREATE OR REPLACE FUNCTION projet.poserCandidature(code_stage VARCHAR(20), motivation VARCHAR(100),
                                                   _id_etudiant INTEGER) RETURNS BOOLEAN AS
$$
DECLARE
    idOffre INTEGER := 0;
BEGIN
    SELECT id_offre_stage FROM projet.offres_de_stages of WHERE of.code_offre_stage = code_stage INTO idOffre;
    INSERT INTO projet.candidatures(motivations, id_offre_stage, id_etudiant)
    VALUES (motivation, idOffre, _id_etudiant);
    return true;
END;
$$ LANGUAGE plpgsql;

--ETUDIANT 4. Voir les offres de stage pour lesquels l’étudiant a posé sa candidature. Pour chaque
--offre, on verra le code de l’offre, le nom de l’entreprise ainsi que l’état de sa candidature.

CREATE OR REPLACE VIEW projet.voirOffresStageEtudiant AS
(
SELECT os.code_offre_stage, en.nom, ca.etat, ca.id_etudiant
FROM projet.offres_de_stages os,
     projet.entreprises en,
     projet.candidatures ca
WHERE en.identifiant_entreprise = os.identifiant_entreprise
  AND os.id_offre_stage = ca.id_offre_stage);

--5.Annuler une candidature en précisant le code de l’offre de stage. Les candidatures ne
-- peuvent être annulées que si elles sont « en attente ».

CREATE OR REPLACE FUNCTION projet.annulerCandidatureTrigger() RETURNS TRIGGER AS
$$
DECLARE

BEGIN
    IF 'acceptée' = (SELECT etat FROM projet.candidatures WHERE id_offre_stage = NEW.id_offre_stage AND id_etudiant = NEW.id_etudiant)THEN
        RAISE 'l''offre a deja été acceptée';
    end if;
    IF NEW.etat = 'annulée' AND OLD.etat != 'en attente' THEN
        RAISE 'Les candidatures ne peuvent être annulées que si elles sont « en attente »';
    end if;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER annulerCandidatureTrigger
    BEFORE UPDATE
    ON projet.candidatures
    FOR EACH ROW
EXECUTE PROCEDURE projet.annulerCandidatureTrigger();

CREATE OR REPLACE FUNCTION projet.annulerCandidature(code_stage_cherche VARCHAR(20), idEtudiant INTEGER) RETURNS VOID AS
$$
DECLARE
    offre INTEGER := 0;
BEGIN
    SELECT id_offre_stage FROM projet.offres_de_stages WHERE code_offre_stage = code_stage_cherche INTO offre;
    UPDATE projet.candidatures SET etat = 'annulée' WHERE id_offre_stage = offre AND id_etudiant = idEtudiant;
END;
$$ LANGUAGE plpgsql;

--SELECT projet.encoderEtudiant('De', 'Jean', 'j.d@student.vinci.be', 'Q2', 'test');
--SELECT projet.encoderEtudiant('Du', 'Marc', 'm.d@student.vinci.be', 'Q1', 'test');
SELECT projet.encoderMotcle('Java');
SELECT projet.encoderMotcle('Web');
SELECT projet.encoderMotcle('Python');
--SELECT projet.encoderEntreprise('VINCI', 'Rue du test, 1', 'vinci@vinci.be', 'VIN', 'test');
SELECT projet.encoderOffreDeStage('stage SAP', 'Q2', 'VIN');
SELECT projet.encoderOffreDeStage('stage BI', 'Q2', 'VIN');
SELECT projet.encoderOffreDeStage('stage Unity', 'Q2', 'VIN');
SELECT projet.encoderOffreDeStage('stage IA', 'Q2', 'VIN');
SELECT projet.encoderOffreDeStage('stage mobile', 'Q1', 'VIN');
SELECT projet.valideroffre('VIN1');
SELECT projet.valideroffre('VIN4');
SELECT projet.valideroffre('VIN5');
SELECT projet.ajouterMotCleOffre('Java', 'VIN3', 'VIN');
SELECT projet.ajouterMotCleOffre('Java', 'VIN5', 'VIN');
SELECT projet.poserCandidature('VIN4', 'Je veux faire un stage chez vous', 1);
SELECT projet.poserCandidature('VIN5', 'Je veux faire un stage chez vous', 2);
--SELECT projet.encoderEntreprise('ULB', 'Rue du test, 1', 'ulb@ulb.be', 'ULB', 'test');
SELECT projet.encoderOffreDeStage('stage javascript', 'Q2', 'ULB');
SELECT projet.valideroffre('ULB1');

-- GRANT CONNECT ON DATABASE dbjulienremmery TO gerardlicaj, nadirahdid;
-- GRANT USAGE ON SCHEMA projet TO gerardlicaj, nadirahdid;
--
-- GRANT USAGE ON ALL SEQUENCES IN SCHEMA projet TO nadirahdid, gerardlicaj;
-- GRANT SELECT ON ALL TABLES IN SCHEMA projet TO nadirahdid, gerardlicaj;
-- GRANT INSERT ON projet.offres_de_stages TO nadirahdid;
-- GRANT insert ON projet.mot_cle_stage TO nadirahdid;
-- GRANT update ON projet.offres_de_stages TO nadirahdid;
-- GRANT update ON projet.candidatures TO nadirahdid, gerardlicaj;
-- GRANT update ON projet.entreprises TO nadirahdid;
-- GRANT INSERT ON projet.candidatures TO gerardlicaj;
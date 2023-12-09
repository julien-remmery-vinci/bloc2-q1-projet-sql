import org.postgresql.util.PSQLException;

import java.sql.*;
import java.util.Scanner;

public class Etudiant {
    static private String semestreEtudiant;
    static private int idEtudiant;
    static String url= "jdbc:postgresql://172.24.2.6:5432/dbjulienremmery";
    static Connection conn=null;
    static Scanner scanner = new Scanner(System.in);
    static PreparedStatement login;
    static PreparedStatement getInfoEtudiant;
    static PreparedStatement afficherOffresStage;
    static PreparedStatement rechercheStageParMotCle;
    static PreparedStatement poserCandidature;
    static PreparedStatement voirOffresStageEtudiant;
    static PreparedStatement annulerCandidature;

    static{
        try {
            try {
                conn = DriverManager.getConnection(url,"julienremmery","CZRMIPHXS");
            } catch (SQLException e) {
                throw new RuntimeException(e);
            }
            login = conn.prepareStatement("SELECT mdp FROM projet.etudiants WHERE email = ?");
            getInfoEtudiant = conn.prepareStatement("SELECT id_etudiant, semestre FROM projet.etudiants WHERE email = ?");
            afficherOffresStage = conn.prepareStatement("SELECT * FROM projet.afficherOffresStage(?) AS (code_offre VARCHAR(20), nom_entreprise VARCHAR(50), adresse_entreprise VARCHAR(100), description_offre VARCHAR(100), mots_cles VARCHAR(60));");
            rechercheStageParMotCle = conn.prepareStatement("SELECT * FROM projet.rechercheStageParMotCle(?, ?) AS (code_offre VARCHAR(20), nom_entreprise VARCHAR(50), adresse_entreprise VARCHAR(100), description_offre VARCHAR(100), mots_cles VARCHAR(60));");
            poserCandidature = conn.prepareStatement("SELECT projet.poserCandidature(?,?,?);");
            voirOffresStageEtudiant = conn.prepareStatement("SELECT code_offre_stage, nom, etat, id_etudiant FROM projet.voirOffresStageEtudiant WHERE id_etudiant = ?;");
            annulerCandidature = conn.prepareStatement("SELECT projet.annulerCandidature(?);");
             } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
    public void connecter(){
        System.out.println("----------------------");
        System.out.println("Application etudiant");
        System.out.println("----------------------");
        while(!login()) {
            System.out.println("Identifiant incorrect");
           login();
        }
        int choix = 0;
        do{
            System.out.println("\n1. Voir toutes les offres de stage dans l’état « validée » correspondant au semestre où l’étudiant fera son stage");
            System.out.println("2. Recherche d’une offre de stage par mot clé");
            System.out.println("3. Poser sa candidature.");
            System.out.println("4. Voir les offres de stage pour lesquels l’étudiant a posé sa candidature");
            System.out.println("5. Annuler une candidature en précisant le code de l’offre de stage");
            choix = Integer.parseInt(scanner.nextLine());
            switch(choix){
                case 1:
                    afficherOffresStage();
                    break;
                case 2:
                    rechercheStageParMotCle();
                    break;
                case 3:
                    poserCandidature();
                    break;
                case 4:
                    voirOffresStageEtudiant();
                    break;
                case 5:
                    annulerCandidature();
                    break;
                default:
                    break;
            }
        } while(choix >= 1 && choix <= 8);
    }
    private boolean login(){
        Scanner scanner = new Scanner(System.in);
        System.out.print("email: ");
        String email = scanner.nextLine();
        System.out.print("mot de passe: ");
        String mdp = scanner.nextLine();
        try {
            login.setString(1, email);
            try(ResultSet rs = login.executeQuery()){
                while (rs.next()) {
                    if(BCrypt.checkpw(mdp, rs.getString(1))) {
                        getInfoEtudiant.setString(1, email);
                        try(ResultSet rs1 = getInfoEtudiant.executeQuery()){
                            while (rs1.next()){
                                idEtudiant = rs1.getInt(1);
                                semestreEtudiant = rs1.getString(2);
                            }
                        }
                        return true;
                    }
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
        return false;
    }
    private static void afficherOffresStage(){
        try {
            afficherOffresStage.setString(1, semestreEtudiant);
            try(ResultSet rs = afficherOffresStage.executeQuery()){
                while (rs.next()) {
                    System.out.println(
                            rs.getString(1) + "\t"+ rs.getString(2) + "\t"+ rs.getString(3) + "\t"+ rs.getString(4)
                    );
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
    private static void rechercheStageParMotCle(){
        System.out.println("mot: ");
        String mot = scanner.nextLine();
        try {
            rechercheStageParMotCle.setString(1, mot);
            rechercheStageParMotCle.setString(2, semestreEtudiant);
            try(ResultSet rs = rechercheStageParMotCle.executeQuery()){
                while (rs.next()) {
                    System.out.println(
                            rs.getString(1) + "\t"+ rs.getString(2) + "\t"+ rs.getString(3) + "\t"+ rs.getString(4) + "\t"+ rs.getString(5));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
    private static void poserCandidature(){
        System.out.print("code stage: ");
        String code = scanner.nextLine();
        System.out.print("motivation: ");
        String motivation = scanner.nextLine();
        try {
            poserCandidature.setString(1, code);
            poserCandidature.setString(2, motivation);
            poserCandidature.setInt(3, idEtudiant);
            poserCandidature.execute();
        } catch (PSQLException pe) {
            pe.printStackTrace();
        } catch (SQLException se) {
            System.out.println("Erreur lors de l’insertion !");
            se.printStackTrace();
            System.exit(1);
        }
    }

    private static void voirOffresStageEtudiant(){
        try {
            voirOffresStageEtudiant.setInt(1, idEtudiant);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
        try(ResultSet rs = voirOffresStageEtudiant.executeQuery()) {
            while(rs.next()){
                System.out.println(
                        rs.getString(1) + "\t"+ rs.getString(2) + "\t"+ rs.getString(3) + "\t"+ rs.getString(4)
                );
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    private static void annulerCandidature(){
        System.out.print("code offre: ");
        String code = scanner.nextLine();
        try {
            annulerCandidature.setString(1, code);
            annulerCandidature.execute();
        } catch (PSQLException pe) {
            pe.printStackTrace();
        } catch (SQLException se) {
            System.out.println("Erreur lors de la requete !");
            se.printStackTrace();
            System.exit(1);
        }
}
}

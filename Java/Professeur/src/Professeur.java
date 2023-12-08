import org.postgresql.util.PSQLException;

import java.sql.*;
import java.util.Scanner;

public class Professeur {

//    static String url= "jdbc:postgresql://localhost:5432/postgres";
        static String url= "jdbc:postgresql://localhost:5432/postgres";
//    static String url= "jdbc:postgresql://172.24.2.6:5432/dbnadirahdid";


    static Connection conn=null;
    static Scanner scanner = new Scanner(System.in);
    static PreparedStatement encoderEtudiant;
    static PreparedStatement encoderEntreprise;
    static PreparedStatement encoderMotCle;
    static PreparedStatement voirOffresNonValidees;
    static PreparedStatement validerOffre;
    static PreparedStatement voirOffresValidees;
    static PreparedStatement voirEtudiantSansStage;
    static PreparedStatement voirOffresAttribuees;

    static{
        try {
            try {

                conn = DriverManager.getConnection(url,"postgres","fvG78Dy%");
//                conn = DriverManager.getConnection(url,"nadirahdid","K51Y3WAJP");

            } catch (SQLException e) {
                throw new RuntimeException(e);
            }
            encoderEtudiant = conn.prepareStatement("SELECT projet.encoderEtudiant(?, ?, ?, ?, ?);");
            encoderEntreprise = conn.prepareStatement("SELECT projet.encoderEntreprise(?, ?, ?, ?, ?);");
            encoderMotCle = conn.prepareStatement("SELECT projet.encoderMotcle(?);");
            voirOffresNonValidees = conn.prepareStatement("SELECT code_offre_stage, semestre, nom, voiroffresnonvalidees.desciption FROM projet.voirOffresNonValidees;");
            validerOffre = conn.prepareStatement("SELECT projet.valideroffre(?);");
            voirOffresValidees = conn.prepareStatement("SELECT code_offre_stage, semestre, nom, description FROM projet.voirOffresValidees;");
            voirEtudiantSansStage = conn.prepareStatement("SELECT nom, prenom, email, semestre, nb_candidatures_attente FROM projet.voirEtudiantsSansStage;");
            voirOffresAttribuees = conn.prepareStatement("SELECT * FROM projet.afficherOffresAttribuees() AS (code_offre VARCHAR(20), nom_entreprise VARCHAR(50), nom_etudiant VARCHAR(50), prenom_etudiant VARCHAR(50));");
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
    public void connecter(){
        System.out.println("----------------------");
        System.out.println("Application professeur");
        System.out.println("----------------------");
        int choix = 0;
        do{
            System.out.println("1. Encoder un étudiant");
            System.out.println("2. Encoder une entreprise");
            System.out.println("3. Encoder un mot-clé que les entreprises pourront utiliser pour décrire leur stage");
            System.out.println("4. Voir les offres de stage dans l’état « non validée »");
            System.out.println("5. Valider une offre de stage en donnant son code");
            System.out.println("6. Voir les offres de stage dans l’état « validée »");
            System.out.println("7. Voir les étudiants qui n’ont pas de stage");
            System.out.println("8. Voir les offres de stage dans l’état « attribuée »");
            choix = scanner.nextInt();
            switch(choix){
                case 1:
                    encoderEtudiant();
                    break;
                case 2:
                    encoderEntreprise();
                    break;
                case 3:
                    encoderMotCle();
                    break;
                case 4:
                    voirOffresNonValidees();
                    break;
                case 5:
                    validerOffre();
                    break;
                case 6:
                    voirOffresValidees();
                    break;
                case 7:
                    voirEtudiantSansStage();
                    break;
                case 8:
                    voirOffresAttribuees();
                    break;
                default:
                    break;
            }
        }while(choix >= 1 && choix <= 8);
        try {
            conn.close();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
    private static void encoderEtudiant(){
        System.out.print("nom: ");
        String nom = scanner.next();
        System.out.print("prenom: ");
        String prenom = scanner.next();
        System.out.print("email: ");
        String email = scanner.next();
        System.out.print("semestre: ");
        String semestre = scanner.next();
        System.out.print("mot de passe: ");
        String mdp = scanner.next();
        String mdpAInserer = BCrypt.hashpw(mdp, BCrypt.gensalt(10));
        try {
            encoderEtudiant.setString(1, nom);
            encoderEtudiant.setString(2, prenom);
            encoderEtudiant.setString(3, email);
            encoderEtudiant.setString(4, semestre);
            encoderEtudiant.setString(5, mdpAInserer);
            encoderEtudiant.execute();
        } catch (PSQLException pe) {
            pe.printStackTrace();
        } catch (SQLException se) {
            System.out.println("Erreur lors de l’insertion !");
            se.printStackTrace();
            System.exit(1);
        }
    }
    private static void encoderEntreprise(){
        System.out.print("nom: ");
        String nom = scanner.next();
        System.out.print("adresse: ");
        String adresse = scanner.next();
        System.out.print("email: ");
        String email = scanner.next();
        System.out.print("identifiant: ");
        String identifiant = scanner.next();
        System.out.print("mot de passe: ");
        String mdp = scanner.next();
        String mdpAInserer = BCrypt.hashpw(mdp, BCrypt.gensalt(10));
        try {
            encoderEntreprise.setString(1, nom);
            encoderEntreprise.setString(2, adresse);
            encoderEntreprise.setString(3, email);
            encoderEntreprise.setString(4, identifiant);
            encoderEntreprise.setString(5, mdpAInserer);
            encoderEntreprise.execute();
        } catch (PSQLException pe) {
            pe.printStackTrace();
        } catch (SQLException se) {
            System.out.println("Erreur lors de l’insertion !");
            se.printStackTrace();
            System.exit(1);
        }
    }
    private static void encoderMotCle(){
        System.out.print("mot: ");
        String mot = scanner.next();
        try {
            encoderMotCle.setString(1, mot);
            encoderMotCle.execute();
        } catch (PSQLException pe) {
            pe.printStackTrace();
        } catch (SQLException se) {
            System.out.println("Erreur lors de l’insertion !");
            se.printStackTrace();
            System.exit(1);
        }
    }
    private static void voirOffresNonValidees(){
        try(ResultSet rs = voirOffresNonValidees.executeQuery()) {
            while (rs.next()) {
                System.out.println(
                        rs.getString(1) + "\t"+ rs.getString(2) + "\t"+ rs.getString(3) + "\t"+ rs.getString(4)
                );
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
    private static void validerOffre(){
        System.out.print("code offre: ");
        String code = scanner.next();
        try {
            validerOffre.setString(1, code);
            validerOffre.execute();
        } catch (PSQLException pe) {
            pe.printStackTrace();
        } catch (SQLException se) {
            System.out.println("Erreur lors de la requete !");
            se.printStackTrace();
            System.exit(1);
        }
    }
    private static void voirOffresValidees(){
        try(ResultSet rs = voirOffresValidees.executeQuery()) {
            while (rs.next()) {
                System.out.println(
                        rs.getString(1) + "\t"+ rs.getString(2) + "\t"+ rs.getString(3) + "\t"+ rs.getString(4)
                );
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
    private static void voirEtudiantSansStage(){
        try(ResultSet rs = voirEtudiantSansStage.executeQuery()) {
            while (rs.next()) {
                System.out.println(
                        rs.getString(1) + "\t"+ rs.getString(2) + "\t"+ rs.getString(3) + "\t"+ rs.getString(4) +"\t"+ rs.getString(5)
                );
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
    private static void voirOffresAttribuees(){
        try(ResultSet rs = voirOffresAttribuees.executeQuery()) {
            while(rs.next()){
                System.out.println(
                        rs.getString(1) + "\t"+ rs.getString(2) + "\t"+ rs.getString(3) + "\t"+ rs.getString(4)
                );
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
}
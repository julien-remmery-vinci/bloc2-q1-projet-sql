import org.postgresql.util.PSQLException;

import java.sql.*;
import java.util.Scanner;

public class Entreprise {

    private static String idEntreprise;
    static String url= "jdbc:postgresql://localhost:5432/postgres";
    //static String url= "jdbc:postgresql://172.24.2.6:5432/dbnadirahdid";
    static Connection conn=null;
    static Scanner scanner = new Scanner(System.in);
    static PreparedStatement login;
    static PreparedStatement encoderOffreDeStage;
    static PreparedStatement ajouterMotCleOffre;
    static PreparedStatement voirSesOffres;
    static PreparedStatement voirCandidatures;
    static PreparedStatement selectionnerEtudiant;
    static PreparedStatement annulerOffre;

    static{
        try {
            try {
                //conn = DriverManager.getConnection(url,"nadirahdid","K51Y3WAJP");
                conn = DriverManager.getConnection(url,"postgres","nadir123");
            } catch (SQLException e) {
                throw new RuntimeException(e);
            }
            login = conn.prepareStatement("SELECT mdp FROM projet.entreprises WHERE email = ?");
            encoderOffreDeStage = conn.prepareStatement("SELECT projet.encoderOffreDeStage(?, ?, ?);");
            ajouterMotCleOffre = conn.prepareStatement("SELECT projet.ajouterMotCleOffre(?, ?);");
            voirSesOffres = conn.prepareStatement("SELECT projet.voirSesOffres(?);");
            voirCandidatures = conn.prepareStatement("SELECT projet.voirCandidatures(?)");
            selectionnerEtudiant = conn.prepareStatement("SELECT projet.selectionnerEtudiant(?, ?, ?);");
            annulerOffre = conn.prepareStatement("SELECT projet.annulerOffre(?);");
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
    public void connecter(){
        System.out.println("----------------------");
        System.out.println("Application entreprise");
        System.out.println("----------------------");
        while(!login()) {
            System.out.println("Identifiant incorrect");
            login();
        }
        int choix = 0;
        do{
            System.out.println("1. Encoder une offre de stage");
            System.out.println("2. Voir mot-clés disponible");
            System.out.println("3. Ajouter un mot-clé");
            System.out.println("4. Voir ses offres");
            System.out.println("5. Voir candidature pour une offre de stage");
            System.out.println("6. Selectionner un étudiant por une de ses offres de stages");
            System.out.println("7. Annuler une offre de stage");
            choix = scanner.nextInt();
            switch(choix){
                case 1:
                    encoderOffreDeStage();
                    break;
                case 2:
                    voirMotCle();
                    break;
                case 3:
                    ajouterMotCleOffre();
                    break;
                case 4:
                    voirSesOffres();
                    break;
                case 5:
                    voirCandidatures();
                    break;
                case 6:
                    selectionnerEtudiant();
                    break;
                case 7:
                    annulerOffre();
                    break;
                default:
                    break;
            }
        }while(choix >= 1 && choix <= 8);
    }
    private boolean login(){
        Scanner scanner = new Scanner(System.in);
        System.out.print("email: ");
        String email = scanner.next();
        System.out.print("mot de passe: ");
        String mdp = scanner.next();
        try {
            login.setString(1, email);
            try(ResultSet rs = login.executeQuery()){
                while (rs.next()) {
                    if(BCrypt.checkpw(mdp, rs.getString(1))) {
                        PreparedStatement getIdEntreprise;
                        getIdEntreprise = conn.prepareStatement("SELECT identifiant_entreprise FROM projet.entreprises WHERE email = ?");
                        getIdEntreprise.setString(1,email);
                        try (ResultSet rs1 = getIdEntreprise.executeQuery()){
                            while(rs1.next()){
                                idEntreprise = rs1.getString(1);
                            }
                        }catch (SQLException e){
                            throw new RuntimeException(e);
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
    private static void encoderOffreDeStage(){
        System.out.print("semestre: ");
        String semestre = scanner.next();
        System.out.print("description: ");
        String description = scanner.next();

        try {
            encoderOffreDeStage.setString(2, semestre);
            encoderOffreDeStage.setString(1, description);
            encoderOffreDeStage.setString(3, idEntreprise);
            encoderOffreDeStage.execute();
        } catch (PSQLException pe) {
            pe.printStackTrace();
        } catch (SQLException se) {
            System.out.println("Erreur lors de l’insertion !");
            se.printStackTrace();
            System.exit(1);
        }
    }
    private static void ajouterMotCleOffre(){
//        System.out.print("nom: ");
//        String nom = scanner.next();
//        System.out.print("adresse: ");
//        String adresse = scanner.next();
//        System.out.print("email: ");
//        String email = scanner.next();
//        System.out.print("identifiant: ");
//        String identifiant = scanner.next();
//        System.out.print("mot de passe: ");
//        String mdp = scanner.next();
//        String mdpAInserer = BCrypt.hashpw(mdp, BCrypt.gensalt(10));
//        try {
//            encoderEtudiant.setString(1, nom);
//            encoderEtudiant.setString(2, adresse);
//            encoderEtudiant.setString(3, email);
//            encoderEtudiant.setString(4, identifiant);
//            encoderEtudiant.setString(5, mdpAInserer);
//            int result = encoderEtudiant.executeUpdate();
//        } catch (PSQLException pe) {
//            pe.printStackTrace();
//        } catch (SQLException se) {
//            System.out.println("Erreur lors de l’insertion !");
//            se.printStackTrace();
//            System.exit(1);
//        }
    }


    private static void voirMotCle(){

    }

    private static void voirSesOffres(){

    }

    private static void selectionnerEtudiant(){

    }
    private static void voirCandidatures(){
//        System.out.print("code offre: ");
//        String code = scanner.next();
//        try {
//            validerOffre.setString(1, code);
//            int result = validerOffre.executeUpdate();
//        } catch (PSQLException pe) {
//            pe.printStackTrace();
//        } catch (SQLException se) {
//            System.out.println("Erreur lors de la requete !");
//            se.printStackTrace();
//            System.exit(1);
//        }
    }

    private static void annulerOffre(){

    }
}

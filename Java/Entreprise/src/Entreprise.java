import org.postgresql.util.PSQLException;

import java.sql.*;
import java.util.Scanner;

public class Entreprise {

    private static String idEntreprise;
    static String url= "jdbc:postgresql://172.24.2.6:5432/dbjulienremmery";
    static Connection conn=null;
    static Scanner scanner = new Scanner(System.in);
    static PreparedStatement login;

    static PreparedStatement voirMotCles;
    static PreparedStatement encoderOffreDeStage;
    static PreparedStatement ajouterMotCleOffre;
    static PreparedStatement voirSesOffres;
    static PreparedStatement voirCandidatures;
    static PreparedStatement selectionnerEtudiant;
    static PreparedStatement annulerOffre;

    static{
        try {
            try {
                conn = DriverManager.getConnection(url,"julienremmery","CZRMIPHXS");
            } catch (SQLException e) {
                throw new RuntimeException(e);
            }
            login = conn.prepareStatement("SELECT mdp FROM projet.entreprises WHERE identifiant_entreprise = ?;");
            voirMotCles = conn.prepareStatement("SELECT mc.mot_cle FROM projet.mots_cles mc;");
            encoderOffreDeStage = conn.prepareStatement("SELECT projet.encoderOffreDeStage(?, ?, ?);");
            ajouterMotCleOffre = conn.prepareStatement("SELECT projet.ajouterMotCleOffre(?, ?);");
            voirSesOffres = conn.prepareStatement("SELECT * FROM projet.voirSesOffres(?) AS (code_offre_stage VARCHAR(20), description VARCHAR(100), semestre VARCHAR(2), etat VARCHAR(11), nb_candidatures_attente INTEGER, attribution VARCHAR(100));");
            voirCandidatures = conn.prepareStatement("SELECT * FROM projet.voirCandidatures(?, ?) AS (etat VARCHAR(10), nom VARCHAR(50),prenom VARCHAR(50),email VARCHAR(100), motivation VARCHAR(100));");
            selectionnerEtudiant = conn.prepareStatement("SELECT projet.selectionnerEtudiant(?, ?, ?);");
            annulerOffre = conn.prepareStatement("SELECT projet.annulerOffre(?,?);");
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
            System.out.println("\n1. Encoder une offre de stage");
            System.out.println("2. Voir mot-clés disponible");
            System.out.println("3. Ajouter un mot-clé");
            System.out.println("4. Voir ses offres");
            System.out.println("5. Voir candidature pour une offre de stage");
            System.out.println("6. Selectionner un étudiant por une de ses offres de stages");
            System.out.println("7. Annuler une offre de stage");
            choix = Integer.parseInt(scanner.nextLine());
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
        System.out.print("identifiant: ");
        idEntreprise = scanner.nextLine();
        System.out.print("mot de passe: ");
        String mdp = scanner.nextLine();
        try {
            login.setString(1, idEntreprise);
            try(ResultSet rs = login.executeQuery()){
                while (rs.next()) {
                    if(BCrypt.checkpw(mdp, rs.getString(1))) {
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
        String semestre = scanner.nextLine();
        System.out.print("description: ");
        String description = scanner.nextLine();

        try {
            encoderOffreDeStage.setString(2, semestre);
            encoderOffreDeStage.setString(1, description);
            encoderOffreDeStage.setString(3, idEntreprise);
            encoderOffreDeStage.execute();
        } catch (SQLException se) {
            System.out.println(se.getMessage());
        }
    }
    private static void ajouterMotCleOffre(){
        System.out.print("mot clé: ");
        String motCle = scanner.nextLine();
        System.out.print("codeOffre: ");
        String codeOffre = scanner.nextLine();
        try {
            ajouterMotCleOffre.setString(1, motCle);
            ajouterMotCleOffre.setString(2, codeOffre);
            ajouterMotCleOffre.execute();
        } catch (SQLException se) {
            System.out.println(se.getMessage());
        }
    }


    private static void voirMotCle(){
        try(ResultSet rs = voirMotCles.executeQuery()){
            while(rs.next()){
                System.out.println(rs.getString(1));
            }
        }catch (SQLException e){
            throw new RuntimeException(e);
        }
    }

    private static void voirSesOffres(){
        try {
            voirSesOffres.setString(1, idEntreprise);
            try(ResultSet rs = voirSesOffres.executeQuery()){
                while(rs.next()){
                    System.out.println(
                            rs.getString(1) + "\t"+ rs.getString(2) + "\t"+ rs.getString(3) + "\t"+ rs.getString(4) +"\t"+ rs.getInt(5)+"\t"+ rs.getString(6)
                    );
                }
            }catch (SQLException e){
                throw new RuntimeException(e);
            }

        } catch (SQLException se) {
            System.out.println(se.getMessage());
        }
    }
    private static void voirCandidatures(){
        System.out.print("code offre: ");
        String code = scanner.nextLine();

        try {
            voirCandidatures.setString(1, code);
            voirCandidatures.setString(2, idEntreprise);
            voirCandidatures.execute();
            try(ResultSet rs = voirCandidatures.executeQuery()){
                    while(rs.next()){
                        System.out.println(
                                rs.getString(1) + "\t"+ rs.getString(2) + "\t"+ rs.getString(3) + "\t"+ rs.getString(4) +"\t"+ rs.getString(5)+"\t"
                        );
                    }
                }catch (SQLException e){
                    throw new RuntimeException(e);
                }
        } catch (SQLException pe) {
            System.out.println(pe.getMessage());
        }
    }
    private static void selectionnerEtudiant(){
        System.out.print("code offre: ");
        String codeOffre = scanner.nextLine();
        System.out.print("email étudiant: ");
        String email = scanner.nextLine();
        try {
            selectionnerEtudiant.setString(1, codeOffre);
            selectionnerEtudiant.setString(2, email);
            selectionnerEtudiant.setString(3, idEntreprise);
            selectionnerEtudiant.execute();
        } catch (SQLException se) {
            System.out.println(se.getMessage());
        }
    }


    private static void annulerOffre(){
        System.out.print("codeOffre: ");
        String codeOffre = scanner.nextLine();
        try {
            annulerOffre.setString(1, codeOffre);
            annulerOffre.setString(2, idEntreprise);
            annulerOffre.execute();
        } catch (SQLException se) {
            System.out.println(se.getMessage());
        }
    }
}



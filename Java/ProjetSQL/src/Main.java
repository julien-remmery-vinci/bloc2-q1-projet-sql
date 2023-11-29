import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class Main {
    public static void main(String[] args) {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL manquant !");
            System.exit(1);
        }
        String url= "jdbc:postgresql://localhost:5432/postgres";
        Connection conn=null;
        try {
            conn = DriverManager.getConnection(url,"postgres","");
            try {
                PreparedStatement ps = conn.prepareStatement("SELECT projet.encoderEtudiant(?, ?, ?, ?, ?);");
                ps.setString(1, "Remmery");
                ps.setString(2, "Julien");
                ps.setString(3, "julien.lebg@student.vinci.be");
                ps.setString(4, "Q1");
                ps.setString(5, "test1");
                ps.executeUpdate();
            } catch (SQLException se) {
                System.out.println("Erreur lors de l’insertion !");
                se.printStackTrace();
                System.exit(1);
            }
        } catch (SQLException e) {
            System.out.println("Impossible de joindre le server !");
            System.exit(1);
        }
    }
}
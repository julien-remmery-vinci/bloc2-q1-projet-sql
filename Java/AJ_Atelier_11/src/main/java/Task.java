public class Task {
    private String titre;
    private String description;
    private String etat;

    public Task(String titre, String description) {
        this.titre = titre;
        this.description = description;
        etat = "Running";
    }

    public String getTitre() {
        return titre;
    }

    public String getDescription() {
        return description;
    }

    public String getEtat() {
        return etat;
    }

    public void setTitre(String titre) {
        this.titre = titre;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public void setEtat(String etat) {
        this.etat = etat;
    }
}

import java.util.ArrayList;
import java.util.List;

public class TodoList {
    private List<Task> tasks = new ArrayList<>();

    public boolean addTask(Task task) {
        if (task.getTitre() == null || task.getDescription() == null) {
            return false;
        }
        if (task.getTitre().isBlank()) {
            return false;
        }
        if(containsTask(task)){
            return false;
        }
        return tasks.add(task);
    }

    public boolean containsTask(Task task) {
        return tasks.contains(task);
    }

    public boolean removeTask(Task task) {
        if(!containsTask(task)){
            for (Task t : tasks) {
                if(task.getTitre().equals(t.getTitre()) && task.getDescription().equals(t.getDescription()))
                    return tasks.remove(t);
            }
        }
        return tasks.remove(task);
    }

    public boolean endTask(Task task) {
        if(!containsTask(task) || task.getEtat() == "Ended") return false;
        task.setEtat("Ended");
        return true;
    }
    public boolean setTitle(Task task, String titre){
        if(titre == null || titre.isBlank()) return false;
        if(!containsTask(task)) return false;
        tasks.get(tasks.indexOf(task)).setTitre(titre);
        return true;
    }
    public boolean setDescription(Task task, String description){
        if(description == null) return false;
        if(!containsTask(task)) return false;
        tasks.get(tasks.indexOf(task)).setDescription(description);
        return true;
    }
    public Task getTask(Task task){
        for (Task t : tasks) {
            if(task.getTitre().equals(t.getTitre()) && task.getDescription().equals(t.getDescription())) return t;
        }
        return null;
    }
    public boolean replaceTask(Task toBeReplaced, Task newTask){
        if(!containsTask(toBeReplaced)) return false;
        Task task = tasks.get(tasks.indexOf(toBeReplaced));
        task.setTitre(newTask.getTitre());
        task.setDescription(newTask.getDescription());
        return true;
    }
}

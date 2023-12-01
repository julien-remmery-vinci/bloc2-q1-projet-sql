import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

public class TodoListTest {
    private TodoList todoList;
    private Task task;


    @BeforeEach
    void setUp() {
        todoList = new TodoList();
        task = new Task("task 1", "description");
    }

    @Test
    void addTask() {
        assertAll(
                () -> assertTrue(todoList.addTask(task)),
                () -> assertTrue(todoList.containsTask(task))
        );
    }
    @Test
    void addEmptyTask() {
        Task nullTask = new Task(null, null);
        assertFalse(todoList.addTask(nullTask));
        assertFalse(todoList.containsTask(nullTask));
        Task emptyTask = new Task("", "");
        assertFalse(todoList.addTask(emptyTask));
        assertFalse(todoList.containsTask(emptyTask));
    }
    @Test
    void addExistingTask() {
        todoList.addTask(task);
        assertFalse(todoList.addTask(task));
    }

    @Test
    void removeTask() {
        todoList.addTask(task);
        assertTrue(todoList.removeTask(task));
        assertFalse(todoList.containsTask(task));
    }

    @Test
    void removeUnexistingTask() {
        assertFalse(todoList.removeTask(task));
    }
}

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;
import static org.junit.jupiter.api.Assertions.assertEquals;

public class TaskTest {
    private TodoList todoList;
    private Task task;

    @BeforeEach
    void setUp() {
        todoList = new TodoList();
        task = new Task("task 1", "description");
    }
    @Test
    void endTask() {
        todoList.addTask(task);
        assertTrue(todoList.endTask(task));
    }

    @Test
    void setTitle() {
        todoList.addTask(task);
        assertTrue(todoList.setTitle(task, "task 2"));
        assertEquals("task 2", task.getTitre());
    }

    @Test
    void setNullOrEmptyTitle() {
        todoList.addTask(task);
        assertFalse(todoList.setTitle(task, null));
        assertFalse(todoList.setTitle(task, ""));
    }

    @Test
    void setDescription() {
        todoList.addTask(task);
        assertTrue(todoList.setDescription(task, "test"));
        assertEquals("test", task.getDescription());
    }
    @Test
    void setNullOrEmptyDescription() {
        todoList.addTask(task);
        assertFalse(todoList.setDescription(task, null));
        assertTrue(todoList.setDescription(task, ""));
    }

    @Test
    void getTask() {
        todoList.addTask(task);
        assertNotNull(todoList.getTask(new Task(task.getTitre(), task.getDescription())));
        assertNull(todoList.getTask(new Task("task 5", "")));
    }

    @Test
    void replaceTask() {
        todoList.addTask(task);
        Task newTask = new Task("task 2", "test 2");
        assertTrue(todoList.replaceTask(task, newTask));
        assertEquals(task.getTitre(), newTask.getTitre());
        assertEquals(task.getDescription(), newTask.getDescription());
    }
}

module TasksHelper
  def task_status(task)
    case
      when !task.completed
        glyph_nonstatus
      when task.failed
        glyph_failure
      else
        glyph_success
    end
  end

  def task_css_class(task)
    case
      when !task.completed
        'task-incomplete'
      when task.failed
        'task-fail'
      else
        'task-success'
    end
  end
end

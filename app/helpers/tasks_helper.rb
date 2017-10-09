module TasksHelper
  def task_status(task)
    case
      when !task.completed
        icon_nonstatus
      when task.failed
        icon_failure
      else
        icon_success
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

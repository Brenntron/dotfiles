module JobsHelper
  def job_collapse_display(task, index)
    3 > index ? "" : "display: none;"
  end

  def job_expand_display(task, index)
    3 > index ? "display: none;" : ""
  end
end

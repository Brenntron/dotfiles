module JobsHelper
  def display_job(task, index)
    3 > index ? "" : "display: none;"
  end

  def display_job2(task, index)
    3 > index ? "display: none;" : ""
  end
end

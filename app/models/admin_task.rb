class AdminTask
  def self.available_tasks
    self.instance_methods - Object.instance_methods
  end  

  def self.execute_task(name, args)
    admin_task = AdminTask.new
    morsel = Morsel.create({:output => " "})
    admin_task.send(name.to_sym, morsel.id, args)

    morsel
  end  

  ######NOTES#######
  #LIKE A RAKE TASK, EACH TASK SHOULD FIT INTO **ONE** INSTANCE METHOD
  #AND IT **MUST** BE AN INSTANCE METHOD TO BE INCLUDED AS AN ELIGIBLE
  #TASK TO RUN
  #def task_name(morsel_id, args)    <--- args will be a hash converted from json
  #end
  #handle_asynchronously :task_name    <--- include this on the line below your task method so that delayed job picks it up


  #Use this test method as a template
  def test_task(morsel_id, args)
    morsel = Morsel.find(morsel_id)
    morsel.output += "\n##################################\n"
    morsel.output += "this is a test, this is only a test:\n"
    morsel.output += "args provided are as follows:\n"
    morsel.output += "#{args.inspect}\n"
    morsel.output += "####################################\n"
    morsel.save
  end
  handle_asynchronously :test_task
  #end of template

  #### REAL TASKS BELOW #######

end

class AdminTask
  def self.available_tasks
    self.instance_methods - Object.instance_methods
  end  

  def self.execute_task(name, args)
    admin_task = AdminTask.new
    morsel = Morsel.create({:output => " "})
    admin_task.send(name.to_sym, morsel, args)
  end  

  ######NOTES#######
  #LIKE A RAKE TASK, EACH TASK SHOULD FIT INTO **ONE** INSTANCE METHOD
  #AND IT **MUST** BE AN INSTANCE METHOD TO BE INCLUDED AS AN ELIGIBLE
  #TASK TO RUN
  #def task_name(morsel, args)



  def test_task(morsel, args)
    morsel.output += "\n##################################\n"
    morsel.output += "this is a test, this is only a test:\n"
    morsel.output += "args provided are as follows:\n"
    morsel.output += "#{args.inspect}\n"
    morsel.output += "####################################\n"
    morsel.save

  end  
end

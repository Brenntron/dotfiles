class WbrsAdminTool


  def self.process(path, arg)
    arg = JSON.parse(arg)
    case path

      when 'webcat1'
        return Wbrs::Prefix.where(arg).inspect.to_s
      when 'webcat2'
        return Wbrs::Prefix.rulelib_rule_sources.inspect.to_s
      when 'webcat3'
        return Wbrs::Prefix.get_certainty_sources_for_urls(arg).inspect.to_s
      when 'webcat4'
        return Wbrs::HistoryRecord.where(arg).inspect.to_s
      when 'webcat5'
        return Wbrs::Cluster.where(arg).inspect.to_s
      when 'webcat6'
        return Wbrs::Category.all.inspect.to_s
      when 'webcat7'
        return Wbrs::TopUrl.check_urls(arg).inspect.to_s
      when 'webrep8'
        id = arg['id']
        return Wbrs::ManualWlbl.find(id).inspect.to_s
      when 'webrep9'
        return Wbrs::ManualWlbl.where(arg).inspect.to_s
      when 'webrep10'
        url = arg['url']
        add = arg['add']
        remove = arg['remove']

        return Wbrs::ManualWlbl.project_new_score(url, add, remove).inspect.to_s

    end

  end
end

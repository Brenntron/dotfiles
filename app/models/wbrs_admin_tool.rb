class WbrsAdminTool


  def self.process(path, arg)

    arg = JSON.parse(arg) unless arg.blank?

    case path

      when 'webcat1'
        return Wbrs::Prefix.where(arg)
      when 'webcat2'
        return Wbrs::Prefix.rulelib_rule_sources
      when 'webcat3'
        return Wbrs::Prefix.get_certainty_sources_for_urls(arg)
      when 'webcat4'
        return Wbrs::HistoryRecord.where(arg)
      when 'webcat5'
        return Wbrs::Cluster.where(arg)
      when 'webcat6'
        return Wbrs::Category.all
      when 'webcat7'
        return Wbrs::TopUrl.check_urls(arg)
      when 'webcat71'
        return Wbrs::RuleUiComplaint.where(arg)["data"]
      when 'webrep8'
        id = arg['id']
        return Wbrs::ManualWlbl.find(id)
      when 'webrep9'
        return Wbrs::ManualWlbl.where(arg)
      when 'webrep10'
        url = arg['url']
        add = arg['add']
        remove = arg['remove']

        return Wbrs::ManualWlbl.project_new_score(url, add, remove)

    end

  end
end

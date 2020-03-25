class ReptoolAdminTool


  def self.process(path, arg)

    arg = JSON.parse(arg) unless arg.blank?

    case path

      when 'reptool1'
        return RepApi::Blacklist.classifications
      when 'reptool2'
        return JSON.parse(RepApi::Blacklist.where(arg, true))
      when 'reptool3'
        return RepApi::Blacklist.add_reptool_entry(arg)
      when 'reptool4'
        return RepApi::Blacklist.expire_reptool_entry(arg)
    end

  end
end

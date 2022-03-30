class TalosEscalationAnalysis
  #TEA in TE parlance
  #This will try to replicate as closely as possible the same TEA data that the TE team uses

  #sources:
  # Virustotal
  # Umbrella
  # Reptool
  # Beaker and/or SDS

  def self.get_data_as_hash(entry, json=false, admin=false)

    tea_data = {}
    tea_data[:entry] = {}
    tea_data[:web_reputation] = {}            #sds and/or beaker
    tea_data[:security_intelligence] = {}     #reptool
    tea_data[:virustotal] = {}                #virustotal
    tea_data[:umbrella] = {}                  #umbrella
    tea_data[:threatgrid] = {}                #threatgrid

    ###WEB REP
    begin
      tea_data[:web_reputation] = get_web_rep_data(entry)
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      if admin==false
        tea_data[:web_reputation] = {}
      else
        tea_data[:web_reputation] = e.message + " " + e.backtrace.join("\n")
      end
    end

    ###REPTOOL
    begin
      tea_data[:security_intelligence] = get_reptool_data(entry)
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      if admin==false
        tea_data[:security_intelligence] = {}
      else
        tea_data[:security_intelligence] = e.message + " " + e.backtrace.join("\n")
      end
    end

    ###VIRUSTOTAL
    begin
      tea_data[:virustotal] = get_virustotal_data(entry)
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      if admin==false
        tea_data[:virustotal] = {}
      else
        tea_data[:virustotal] = e.message + " " + e.backtrace.join("\n")
      end
    end

    ###UMBRELLA
    begin
      tea_data[:umbrella] = get_umbrella_data(entry)
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      if admin==false
        tea_data[:umbrella] = {}
      else
        tea_data[:umbrella] = e.message + " " + e.backtrace.join("\n")
      end
    end



    if json == true
      tea_data.as_json
    else
      tea_data
    end

  end

  def self.get_web_rep_data(entry)

  end

  def self.get_reptool_data(entry)

  end

  def self.get_virustotal_data(entry)

  end

  def self.get_umbrella_data(entry)

  end

end

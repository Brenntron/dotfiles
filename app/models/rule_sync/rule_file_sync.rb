module RuleSync
  class RuleFileSync
    # For each given filename, checks out latest from svn and read into db.
    def self.sync(filename_list)
      # Note: API definition is comma separated list.
      # However, since we are taking input from the web as parameters of a UNIX shell command line,
      # splitting by semicolon will make injection attacks harder.
      new(filename_list.strip.split(/\s*[,;]\s*/)).tap do |sync|
        sync.sync
      end
    end

    def initialize(filenames)
      @filenames = filenames
    end

    # For each given filename, checks out latest from svn and read into db.
    def sync
      ac_root = Pathname.new(Rails.configuration.ac_root)
      sync_script_path = ac_root.join('extras', 'synch_rules.sh')

      @filenames.each do |filename|
        next unless /[-\w]+\/[-\w]+.rules/ =~ filename

        filepath = ac_root.join('extras', 'snort', filename)

        # next unless File.directory?(dirpath)
        next unless File.directory?(filepath.dirname)

        `svn up #{filepath}`
        `cd #{Rails.configuration.ac_root};#{sync_script_path} #{filepath}`
      end
    end
  end
end

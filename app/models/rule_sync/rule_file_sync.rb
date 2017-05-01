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
      sync_script_path = Rails.root.join('extras', 'synch_rules.sh')

      @filenames.each do |filename|
        next unless /[-\w]+\/[-\w]+.rules/ =~ filename

        dirpath = Pathname.new(Rails.configuration.ac_root).join('extras', 'snort', File.dirname(filename))
        basename = File.basename(filename)
        filepath = dirpath.join(basename)

        next unless File.directory?(dirpath)

        # TODO replace touch with svc checkout
        # TODO remove echo
        # TODO remove puts
        puts `svn up #{filepath}`
        puts `cd #{dirpath};touch #{basename};echo #{sync_script_path} #{filepath}`
      end
    end
  end
end

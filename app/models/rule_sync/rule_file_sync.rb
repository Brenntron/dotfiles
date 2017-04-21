module RuleSync
  class RuleFileSync
    # For each given filename, checks out latest from svn and read into db.
    def self.sync(filename_list)
      new(filename_list.strip.split(/\s*,\s*/)).tap do |sync|
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
        dirpath = Rails.root.join('extras', 'snort', File.dirname(filename))
        basename = File.basename(filename)
        filepath = Rails.root.join('extras', 'snort', filename)

        next unless File.directory?(dirpath)
        # TODO replace touch with svc checkout
        # TODO remove echo
        # TODO remove puts
        puts `cd #{dirpath};touch #{basename};echo #{sync_script_path} #{filepath}`
      end
    end
  end
end

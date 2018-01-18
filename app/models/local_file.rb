class LocalFile < FileReference
  def filepath
    location
  end

  # Constructs object from a file and writes contents to a local file on the filesystem.
  # @param [IO] in_file File which can be read
  # @param [String] relative_path path to use when creating the file
  # @param [Hash] attrs values to use for file_name, file_type_name, and any other attributes
  def self.copy_local(in_file, relative_path, attrs)
    local = LocalFile.create(attrs)
    local.location = File.join('lib/data/local', relative_path)
    File.open(location, 'w') do |out_file|
      out_file.write(in_file.read)
    end
    save!
    self
  end
end

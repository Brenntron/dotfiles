class LocalFile < FileReference
  def filepath
    location
  end

  def copy_local(in_file, relative_path)
    self.location = File.join('lib/data/local', relative_path)
    File.open(location, 'w') do |out_file|
      out_file.write(in_file.read)
    end
    save!
    self
  end
end

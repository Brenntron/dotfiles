module AdminHelper
  def file_size(*path)
    filepath = File.join(*path)
    File.size(filepath)
  end

  def beginning_contents(*path)
    filepath = File.join(*path)
    File.open(filepath, 'r') { |file| file.readpartial(80) }
  end
end

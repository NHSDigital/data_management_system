# lifted mostly from rubyzip gem examples
class ZipFolderCopy
  attr_accessor :input_dir, :zipfile, :folder_path

  def initialize(input_dir, zipfile, folder_path = nil)
    @input_dir = input_dir
    @zipfile = zipfile
    @folder_path = folder_path
  end

  # Zip the input directory.
  def write
    entries = Dir.entries(input_dir)
    clean_paths(entries)
    write_entries(entries, '')
  end

  private

  # A helper method to make the recursion work.
  def write_entries(entries, path)
    entries.each do |e|
      zip_file_path = path.empty? ? e : File.join(path, e)
      zip_folder = folder_path.nil? ? zip_file_path : "#{folder_path}#{zip_file_path}"
      disk_file_path = File.join(input_dir, zip_file_path)
      if File.directory?(disk_file_path)
        zipfile.mkdir(zip_folder)
        subdir = Dir.entries(disk_file_path)
        clean_paths(subdir)
        write_entries(subdir, zip_file_path)
      else
        zipfile.get_output_stream(zip_folder) { |f| f.write(File.open(disk_file_path, 'rb').read) }
      end
    end
  end

  def clean_paths(dir)
    ['.', '..'].each { |d| dir.delete(d) }
  end
end

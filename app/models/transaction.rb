require 'fileutils'
require 'hashids'
require 'tempfile'

# Represents an ingest package, consisting of a set of files.
class Transaction < ApplicationRecord
  validates :owner, presence: true

  # tag is needed to create a unique directory
  # to store the files; it's set during the stash! process
  validates :tag, presence: true

  validates :files, length: { minimum: 1 }

  after_initialize :initialize_directories

  def initialize_directories(_ = {}, options = {})
    self.owner ||= 'trln'
    timestamp = created_at || Time.now
    base_dir = options[:base_dir] || Rails.application.config.stash_directory
    day_dir = timestamp.strftime("%Y#{File::SEPARATOR}%m#{File::SEPARATOR}%d")
    self.status ||= 'New'
    self.tag = generate_tag(timestamp) unless tag
    self.stash_directory = File.join(base_dir, owner, day_dir, tag)
  end

  ##
  # Stashes current files in the transaction's directory
  # modifies the 'files' attribute to contain the stashed files
  # and sets the 'stash_directory' if it isn't already set
  # Typically this method must be called before saving the transaction
  def stash!
    stash_files = prepare_stash! unless
      stash_directory && File.directory?(stash_directory)
    FileUtils.mkdir_p(stash_directory) unless File.directory?(stash_directory)
    files.zip(stash_files).each do |source, dest|
      # try to be idempotent
      if File.exist?(source)
        FileUtils.mv(source, dest) unless File.exist?(dest)
      end
    end
    self.files = stash_files
  end

  def error_files
    return [] unless files
    files.grep(/error/i)
  end

  def errors
    error_files.map do |filename|
      File.open(filename) do |f|
        Argot::Reader.new(f).collect.to_a
      end
    end.flatten
  end

  private

  def absolutize_file(filename)
    File.join(stash_directory, File.basename(filename)) if File.exist?(filename)
  end

  def prepare_stash!
    files.collect { |f| absolutize_file(f) }.select { |x| x }
  end

  # generate reversible, short-ish tag for this set of files; mostly used as
  # a surrogate identifier
  # and fodder for a directory name when stashing
  # rubocop:disable MethodLength
  def generate_tag(timestamp)
    # random-ish seed
    hasher = Hashids.new('Niangle Lesearch Ribraries Tretwork')
    filesize = 0
    files.each { |f| filesize += f.size }
    hasher.encode(filesize,
                  timestamp.year,
                  timestamp.month,
                  timestamp.day,
                  timestamp.hour,
                  timestamp.min,
                  timestamp.sec,
                  timestamp.nsec)
  end
  # rubocop:enable MethodLength
end

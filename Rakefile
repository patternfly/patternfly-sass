require 'rake'
require 'rspec/core/rake_task'

BOOTSTRAP_GEM_ROOT = Gem::Specification.find_by_name("bootstrap-sass").gem_dir
FONTAWESOME_GEM_ROOT = Gem::Specification.find_by_name("font-awesome-sass").gem_dir

desc "Convert LESS to SCSS"
task :convert, [:branch] do |_, args|
  require './tasks/converter'
  branch = args.has_key?(:branch) ? args[:branch] : 'master'
  Patternfly::Converter.new(:branch => branch).process_patternfly
end

desc "Compile patternfly-sass into CSS"
task :compile do
  require 'sass'
  require 'fileutils'
  require 'term/ansicolor'

  Sass.load_paths << File.join(BOOTSTRAP_GEM_ROOT, 'assets', 'stylesheets')
  Sass.load_paths << File.join(FONTAWESOME_GEM_ROOT, 'assets', 'stylesheets')
  Sass::Script::Number.precision = 8

  path = 'assets/stylesheets'
  FileUtils.mkdir_p('tmp')

  puts Term::ANSIColor.bold "Compiling SCSS in #{path}"

  %w(patternfly.css patternfly.min.css).each do |out|
    style = (out == "patternfly.min.css") ? :compressed : :nested
    src_path = File.join(path, '_patternfly.scss')
    dst_path = File.join('tmp', out)
    engine = Sass::Engine.for_file(src_path, :syntax => :scss, :load_paths => [path], :style => style)
    css = engine.render
    File.open(dst_path, 'w') { |f| f.write css }
    puts Term::ANSIColor.cyan("  #{dst_path}") + '...'
  end
end

desc "Start a web server with both the less and the sass version"
task :serve do
  require 'webrick'
  server = WEBrick::HTTPServer.new :Port => 9000, :DirectoryIndex => []
  {
    '/'                                   => 'tests/index.html',
    '/less/dist'                          => 'tests/patternfly/dist',
    '/less/components'                    => 'tests/components',
    '/less/components/bootstrap/dist/js'  => File.join(BOOTSTRAP_GEM_ROOT, 'assets', 'javascripts'),
    '/less/components/font-awesome/fonts' => File.join(FONTAWESOME_GEM_ROOT, 'assets', 'fonts', 'font-awesome'),
    '/less/patternfly'                    => 'tests/patternfly',
    '/sass/dist/fonts'                    => 'tests/patternfly/dist/fonts',
    '/sass/dist/img'                      => 'tests/patternfly/dist/img',
    '/sass/dist/js'                       => 'tests/patternfly/dist/js',
    '/sass/dist/css'                      => 'tmp',
    '/sass/components'                    => 'tests/components',
    '/sass/components/bootstrap/dist/js'  => File.join(BOOTSTRAP_GEM_ROOT, 'assets', 'javascripts'),
    '/sass/components/font-awesome/fonts' => File.join(FONTAWESOME_GEM_ROOT, 'assets', 'fonts', 'font-awesome'),
    '/sass/patternfly'                    => 'tests/patternfly'
  }.each { |http, local| server.mount http, WEBrick::HTTPServlet::FileHandler, local }

  trap('INT') { server.stop }
  server.start
end

desc "Clean up the test results"
task :cleanup do
  require 'fileutils'
  FileUtils.rm_rf '.sass-cache'
  FileUtils.rm_rf 'tests/less'
  FileUtils.rm_rf 'tests/sass'
  FileUtils.rm_rf 'tests/failures'
end

desc "Run the tests with a web server"
task :test do
  pid = Process.fork do
    puts "Starting web server on port 9000"
    $stdout.reopen('/dev/null', 'w')
    $stderr.reopen('/dev/null', 'w')
    Rake::Task[:serve].invoke
    puts "Stopping web server on port 9000"
  end
  sleep(3) # Give some time for the web server to start
  puts "Starting the tests against the web server"
  begin
    Rake::Task[:spec].invoke
  ensure
    Process.kill('INT', pid)
  end
end

desc "Run the tests without a web server"
RSpec::Core::RakeTask.new(:spec) do |t|
  Rake::Task[:cleanup].invoke
  FileUtils.mkdir_p 'tests/less'
  FileUtils.mkdir_p 'tests/sass'
  FileUtils.mkdir_p 'tests/failures'
  t.pattern = Dir.glob('spec/**/*_spec.rb')
end

task :upload do
  require 'imgur'
  require 'term/ansicolor'

  # Travis only task, exit when the IMGUR_ID is not present
  exit(0) if ENV['IMGUR_ID'].nil?

  print Term::ANSIColor.bold "Uploading failure diffs to imgur "

  client = Imgur.new ENV['IMGUR_ID']
  images = Dir["tests/failures/*.png"].map do |img|
    print Term::ANSIColor.cyan '.'
    client.upload Imgur::LocalImage.new(img, :title => img.sub('.png', '.html').sub('tests/failures/', ''))
  end

  if images.empty?
    puts Term::ANSIColor.cyan ' nothing to upload'
  else
    album = client.new_album(images, :title => "patternfly-sass CI results for build ##{ENV['TRAVIS_BUILD_NUMBER']}")
    puts Term::ANSIColor.bold " available at: #{Term::ANSIColor.cyan album.link}"
  end
end

task :default => :convert

require 'rake'
require 'rspec/core/rake_task'

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

  BOOTSTRAP_GEM_ROOT = Gem::Specification.find_by_name("bootstrap-sass").gem_dir
  FONTAWESOME_GEM_ROOT = Gem::Specification.find_by_name("font-awesome-sass").gem_dir

  Sass.load_paths << File.join(BOOTSTRAP_GEM_ROOT, 'assets', 'stylesheets')
  Sass.load_paths << File.join(FONTAWESOME_GEM_ROOT, 'assets', 'stylesheets')
  Sass::Script::Number.precision = 8

  path = 'sass'
  css_path = 'dist/css'
  FileUtils.mkdir_p(css_path)

  puts Term::ANSIColor.bold "Compiling SCSS in #{path}"

  %w(patternfly.css patternfly.min.css).each do |save_path|
    style = (save_path == "patternfly.min.css") ? :compressed : :nested
    save_path = "dist/css/#{save_path}"
    engine = Sass::Engine.for_file("#{path}/patternfly.scss", :syntax => :scss, :load_paths => [path], :style => style)
    css = engine.render
    File.open(save_path, 'w') { |f| f.write css }
    puts Term::ANSIColor.cyan("  #{save_path}") + '...'
  end
end

desc "Start a web server with both the less and the sass version"
task :serve do
  require 'rack'
  app, _ = Rack::Builder.parse_file('config.ru')
  Rack::Handler::Thin.run(app, :Port => 9000)
end

desc "Clean up the test results"
task :cleanup do
  require 'fileutils'
  FileUtils.rm_rf 'tmp'
  FileUtils.rm_rf '.sass-cache'
  FileUtils.rm_rf 'tests/less'
  FileUtils.rm_rf 'tests/sass'
  FileUtils.rm_rf 'tests/failures'
end

desc "Run the tests"
task :test => :spec

desc "Run the tests without a web server"
RSpec::Core::RakeTask.new(:spec => :cleanup) do |t|
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

desc "Convert LESS to SCSS"
task :convert, [:branch] do |t, args|
  require './tasks/converter'
  branch = args.has_key?(:branch) ? args[:branch] : 'master'
  Patternfly::Converter.new(:branch => branch).process_patternfly
end

desc "Compile patternfly-sass into CSS"
task :compile do
  require 'sass'
  require 'fileutils'
  require 'term/ansicolor'

  Sass::Script::Number.precision = 8

  path = 'sass'
  css_path = 'dist/css'
  FileUtils.mkdir_p(css_path)

  puts Term::ANSIColor.bold "Compiling SCSS in #{path}"

  %w(patternfly.css patternfly.min.css).each do |save_path|
    style = (save_path == "patternfly.min.css") ? :compressed : :nested
    save_path = "dist/css/#{save_path}"
    engine = Sass::Engine.for_file("#{path}/patternfly.scss", syntax: :scss, load_paths: [path], style: style)
    css = engine.render
    File.open(save_path, 'w') { |f| f.write css }
    puts Term::ANSIColor.cyan("  #{save_path}") + '...'
  end
end

desc "Start a web server with both the less and the sass version"
task :serve do
  require 'webrick'
  server = WEBrick::HTTPServer.new :Port => 9000, :DirectoryIndex => []
  {
    '/'                => 'tests/index.html',
    '/less/dist'       => 'components/patternfly/dist',
    '/less/components' => 'components/patternfly/components',
    '/less/patternfly' => 'tests/patternfly',
    '/sass/dist'       => 'components/patternfly/dist',
    '/sass/dist/css'   => 'dist/css',
    '/sass/components' => 'components/patternfly/components',
    '/sass/patternfly' => 'tests/patternfly'
  }.each { |http, local| server.mount http, WEBrick::HTTPServlet::FileHandler, local }

  trap('INT') { server.stop }
  server.start
end

task default: :convert

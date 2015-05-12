desc "Convert LESS to SCSS"
task :convert, [:branch] do |t, args|
  require './tasks/converter'
  branch = args.has_key?(:branch) ? args[:branch] : 'master'
  Patternfly::Converter.new(:branch => branch).process_patternfly
end

task :compile do
  require 'sass'
  require 'term/ansicolor'

  Sass::Script::Number.precision = 8

  path = 'sass'
  css_path = 'dist/css'
  Dir.mkdir(css_path) unless File.directory?(css_path)

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

task :upload do
  require 'imgur'
  require 'term/ansicolor'

  client = Imgur.new ENV['IMGUR_ID']
  images = Dir["tests/failures/*.png"].map { |img| client.upload Imgur::LocalImage.new(img, :title => img.sub('.png', '')) }

  unless images.empty?
    album = client.new_album(images, :title => "patternfly-sass build ##{ENV['TRAVIS_BUILD_NUMBER']} failures #{Time.now}")
    puts Term::ANSIColor.bold "Failure image diffs uploaded to: #{Term::ANSIColor.red album.link}"
  end
end

task default: :convert

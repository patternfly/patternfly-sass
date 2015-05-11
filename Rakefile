
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

task default: :convert

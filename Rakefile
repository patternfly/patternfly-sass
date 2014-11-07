
desc "Convert LESS to SCSS"
task :convert, [:branch] do |t, args|
  require './tasks/converter'
  branch = args.key?(:branch) ? args[:branch] : 'master'
  Patternfly::Converter.new(:branch => branch).process_patternfly
end

task default: :convert

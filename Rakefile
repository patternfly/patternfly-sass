
desc "Convert LESS to SCSS"
task :convert, [:branch] do |t, args|
  require './tasks/converter'
  Patternfly::Converter.new(branch: args[:branch]).process_patternfly
end

task default: :convert

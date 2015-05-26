lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'patternfly-sass/version'

Gem::Specification.new do |s|
  s.name     = "patternfly-sass"
  s.version  = Patternfly::VERSION
  s.authors  = ["Dávid Halász", "Alex Wood"]
  s.email    = 'patternflyui@gmail.com'
  s.summary  = "Red Hat's Patternfly, converted to Sass and ready to drop into Rails"
  s.homepage = "https://github.com/Patternfly/patternfly-sass"
  s.license  = 'MIT'

  s.add_runtime_dependency 'sass', '~> 3.2'
  s.add_runtime_dependency 'bootstrap-sass', '~> 3.3.4'
  s.add_runtime_dependency 'font-awesome-sass', '~> 4.3.0'

  # Converter's dependencies
  s.add_development_dependency 'rake', '~> 10.4'
  s.add_development_dependency 'term-ansicolor'
  # Testing dependencies
  s.add_development_dependency 'rspec', '~> 3.2'
  s.add_development_dependency 'nokogiri', '~> 1.6'
  s.add_development_dependency 'rmagick', '~> 2.15'
  s.add_development_dependency 'imgur-api', '~> 0.0.4'

  s.files      = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- tests/*`.split("\n") + `git ls-files -- spec/*`.split("\n")
end

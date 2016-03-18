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
  s.license  = 'Apache-2.0'

  s.add_runtime_dependency 'sass', '~> 3.4.15'
  s.add_runtime_dependency 'bootstrap-sass', '~> 3.3.6'
  s.add_runtime_dependency 'font-awesome-sass', '~> 4.5.0'

  # Converter's dependencies
  s.add_development_dependency 'rake', '~> 10.4'
  s.add_development_dependency 'term-ansicolor'
  s.add_development_dependency 'rugged', '~> 0.23.2'
  # Testing dependencies
  s.add_development_dependency 'rspec', '~> 3.2'
  s.add_development_dependency 'nokogiri', '~> 1.6'
  s.add_development_dependency 'rmagick', '~> 2.15'
  s.add_development_dependency 'imgur-api', '~> 0.0.4'
  s.add_development_dependency 'selenium-webdriver', '~> 2.46'

  s.files      = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- spec/*`.split("\n")
end

require 'rack'

url_map = {
  '/'                => 'tests/',
  '/less/dist'       => 'tests/patternfly/dist',
  '/less/components' => 'components/patternfly/components',
  '/less/patternfly' => 'tests/patternfly',
  '/sass/dist/'      => 'tests/patternfly/dist',
  '/sass/dist/css'   => 'dist/css',
  '/sass/components' => 'components/patternfly/components',
  '/sass/patternfly' => 'tests/patternfly',
}
url_map.each do |k, v|
  url_map[k] = Rack::Directory.new(v)
end

run Rack::URLMap.new(url_map)

require 'net/http'
require 'nokogiri'
require 'rmagick'
require 'thin'

describe "compare SASS with LESS screenshots" do
  BASEURL = "http://localhost:9000"
  RESOLUTIONS = [[320, 480], [768, 1024], [1280, 1024]]
  CONTEXTS = %w(less sass)
  TOLERANCE = 0.05

  before(:all) do
    ['less', 'sass', 'failures'].each do |dir|
      dest = File.join('tests', dir)
      FileUtils.mkdir_p(dest)
      FileUtils.rm(Dir.glob(File.join(dest, '*.png')))
    end

    app, _ = Rack::Builder.parse_file('config.ru')
    @server = Thread.new do
      Thin::Server.start('0.0.0.0', 9000, app)
    end
    sleep(2) # Give the server some time to start
  end

  after(:all) do
    @server.kill unless @server.nil?
  end

  html = File.open(File.join("tests", "patternfly", "index.html"))
  document = Nokogiri::HTML(html)

  document.css(".row a").each do |link|
    file = link['href']
    context "#{file}" do
      title = file.sub('.html', '')
      RESOLUTIONS.each do |w,h|
        it "#{w}x#{h}" do
          file_name = "#{title}-#{w}x#{h}.png"
          CONTEXTS.each do |ctx|
            destination = File.join('tests', ctx, file_name)
            `phantomjs tests/capture.js #{w} #{h} '#{BASEURL}/#{ctx}/patternfly/#{file}' #{destination}`
          end
          img_less = Magick::Image.read(File.join('tests', 'less', file_name)).first
          img_sass = Magick::Image.read(File.join('tests', 'sass', file_name)).first

          cols = [img_less.base_columns, img_sass.base_columns].max
          rows = [img_less.base_rows, img_sass.base_rows].max
          img_base = Magick::Image.new(cols, rows) { self.background_color = 'black' }

          img_less = img_base.composite(img_less, 0, 0, Magick::OverCompositeOp)
          img_sass = img_base.composite(img_sass, 0, 0, Magick::OverCompositeOp)

          img_diff, diff_rate = img_less.compare_channel img_sass, Magick::MeanAbsoluteErrorMetric, Magick::AllChannels

          img_diff.write(File.join('tests', 'failures', file_name)) unless diff_rate <= TOLERANCE
          expect(diff_rate).to be <= TOLERANCE
        end
      end
    end
  end
end

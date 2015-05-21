require 'net/http'
require 'nokogiri'
require 'rmagick'

RSpec.describe "compare SASS with LESS screenshots" do
  BASEURL = "http://localhost:9000"
  RESOLUTIONS = [[320, 480], [768, 1024], [1280, 1024]]
  CONTEXTS = %w(less sass)
  TOLERANCE = 0.05

  html = Net::HTTP.get(URI("#{BASEURL}/less/patternfly/index.html"))
  document = Nokogiri::HTML(html)

  document.css(".row a").each do |link|
    file = link['href']
    context "#{file}" do
      title = file.sub('.html', '')
      RESOLUTIONS.each do |w, h|
        it "#{w}x#{h}" do
          CONTEXTS.each do |ctx|
            `phantomjs tests/capture.js #{w} #{h} #{BASEURL}/#{ctx}/patternfly/#{file} tests/#{ctx}/#{title}-#{w}x#{h}.png`
          end

          if File.exist?("tests/less/#{title}-#{w}x#{h}.png") && File.exist?("tests/sass/#{title}-#{w}x#{h}.png")
            img_less = Magick::Image.read("tests/less/#{title}-#{w}x#{h}.png").first
            img_sass = Magick::Image.read("tests/sass/#{title}-#{w}x#{h}.png").first
          end
          expect(img_less).not_to be_nil
          expect(img_sass).not_to be_nil

          cols = [img_less.base_columns, img_sass.base_columns].max
          rows = [img_less.base_rows, img_sass.base_rows].max
          img_base = Magick::Image.new(cols, rows) { self.background_color = 'black' }

          img_less = img_base.composite(img_less, 0, 0, Magick::OverCompositeOp)
          img_sass = img_base.composite(img_sass, 0, 0, Magick::OverCompositeOp)

          img_diff, diff_rate = img_less.compare_channel img_sass, Magick::MeanAbsoluteErrorMetric, Magick::AllChannels

          img_diff.write("tests/failures/#{title}-#{w}x#{h}.png") unless diff_rate <= TOLERANCE
          expect(diff_rate).to be <= TOLERANCE
        end
      end
    end
  end
end

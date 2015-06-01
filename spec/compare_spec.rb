require 'net/http'
require 'nokogiri'
require 'rmagick'

RSpec.describe "compare SASS with LESS screenshots" do
  BASEURL = "http://localhost:9000"
  RESOLUTIONS = [[320, 480], [768, 1024], [1280, 1024]]
  CONTEXTS = %w(less sass)

  # TODO: Set this to 0 when SASS 3.4.15 is released.
  # See https://github.com/sass/sass/issues/1732
  TOLERANCE = 0.05

  html = Net::HTTP.get(URI("#{BASEURL}/less/patternfly/index.html"))
  document = Nokogiri::HTML(html)

  document.css(".row a").each do |link|
    file = link['href']
    context "#{file}" do
      title = file.sub('.html', '')
      RESOLUTIONS.each do |w,h|
        it "#{w}x#{h}" do
          CONTEXTS.each do |ctx|
            `phantomjs tests/capture.js #{w} #{h} #{BASEURL}/#{ctx}/patternfly/#{file} tests/#{ctx}/#{title}-#{w}x#{h}.png`
          end
          img_less = Magick::Image.read("tests/less/#{title}-#{w}x#{h}.png").first
          img_sass = Magick::Image.read("tests/sass/#{title}-#{w}x#{h}.png").first

          cols = [img_less.base_columns, img_sass.base_columns].max
          rows = [img_less.base_rows, img_sass.base_rows].max

          img_less.resize_to_fill!(cols, rows)
          img_sass.resize_to_fill!(cols, rows)

          img_diff, diff_rate = img_less.compare_channel img_sass, Magick::MeanAbsoluteErrorMetric, Magick::AllChannels
          img_less.destroy!
          img_sass.destroy!

          img_diff.write("tests/failures/#{title}-#{w}x#{h}.png") unless diff_rate <= TOLERANCE
          img_diff.destroy!
          expect(diff_rate).to be <= TOLERANCE
        end
      end
    end
  end
end

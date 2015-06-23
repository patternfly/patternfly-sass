require 'net/http'
require 'nokogiri'
require 'rmagick'
require 'selenium-webdriver'

RSpec.describe "compare SASS with LESS screenshots" do
  BASEURL = "http://localhost:9000"
  RESOLUTIONS = [[320, 480], [768, 1024], [1280, 1024]]
  CONTEXTS = %w(less sass)

  # TODO: Set this to 0 when SASS 3.4.15 is released.
  # See https://github.com/sass/sass/issues/1732
  TOLERANCE = 0.05

  driver = Selenium::WebDriver.for(:phantomjs)

  # Give some time for the testing server to start
  html = nil
  5.times do |t|
    html = Net::HTTP.get(URI("#{BASEURL}/less/patternfly/index.html")) rescue nil
    break unless html.nil?
    sleep(t + 1)
  end
  raise Errno::ECONNREFUSED if html.nil?
  document = Nokogiri::HTML(html)

  document.css(".row a").each do |link|
    file = link['href']
    context "#{file}" do
      title = file.sub('.html', '')
      RESOLUTIONS.each do |w, h|
        it "#{w}x#{h}" do
          driver.manage.window.resize_to(w, h)
          CONTEXTS.each do |ctx|
            driver.navigate.to("#{BASEURL}/#{ctx}/patternfly/#{file}")
            driver.execute_script("
              var style = document.createElement('style');
              style.innerHTML = '* { -webkit-animation: none !important; -webkit-transition: none !important;';
              document.body.appendChild(style);
            ")
            sleep(1)
            driver.save_screenshot("spec/results/#{ctx}/#{title}-#{w}x#{h}.png")
          end
          img_less = Magick::Image.read("spec/results/less/#{title}-#{w}x#{h}.png").first
          img_sass = Magick::Image.read("spec/results/sass/#{title}-#{w}x#{h}.png").first

          cols = [img_less.base_columns, img_sass.base_columns].max
          rows = [img_less.base_rows, img_sass.base_rows].max

          img_less.resize_to_fill!(cols, rows)
          img_sass.resize_to_fill!(cols, rows)

          img_diff, diff_rate = img_less.compare_channel img_sass, Magick::MeanAbsoluteErrorMetric, Magick::AllChannels
          img_less.destroy!
          img_sass.destroy!

          img_diff.write("spec/results/#{title}-#{w}x#{h}.png") unless diff_rate <= TOLERANCE
          img_diff.destroy!
          expect(diff_rate).to be <= TOLERANCE
        end
      end
    end
  end

  after(:all) do
    driver.quit
  end
end

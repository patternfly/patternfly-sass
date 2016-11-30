require 'selenium-webdriver'
require 'nokogiri'
require 'rmagick'

RSpec.describe "compare SASS with LESS screenshots" do
  BASEURL = "http://localhost:9000"
  RESOLUTIONS = [[320, 480], [768, 1024], [1280, 1024]]
  CONTEXTS = %w(less sass)
  TOLERANCE = ENV['TOLERANCE'].to_f || 0.00
  BROWSER = (ENV['BROWSER'] || :chrome).to_sym

  before(:all) do
    Selenium::WebDriver::Chrome.driver_path = 'chromedriver/chromedriver' if ENV['CI'] && ENV['BROWSER'] == 'chrome'
    @browser = Selenium::WebDriver.for(BROWSER)
  end

  puts "Starting tests with TOLERANCE=#{TOLERANCE}"
  html = File.read('spec/html/index.html')
  document = Nokogiri::HTML(html)

  document.css(".row a").each do |link|
    file = link['href']
    context "#{file}" do
      title = file.sub('.html', '')
      RESOLUTIONS.each do |w, h|
        it "#{w}x#{h}" do
          @browser.manage.window.resize_to(w, h)
          CONTEXTS.each do |ctx|
            @browser.navigate.to("#{BASEURL}/#{ctx}/pages/patternfly/#{file}")
            @browser.execute_script("
              var style = document.createElement('style');
              style.innerHTML = '* { -moz-animation: none !important; -moz-transition: none !important; -webkit-animation: none !important; -webkit-transition: none !important; }';
              document.body.appendChild(style);
            ")
            sleep(1)
            @browser.save_screenshot("spec/results/#{ctx}/#{title}-#{w}x#{h}.png")
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

  after(:all) { @browser.quit }
end

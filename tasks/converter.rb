bootstrap_sass = Gem::Specification.find_by_name("bootstrap-sass").gem_dir
require "#{bootstrap_sass}/tasks/converter"

module Patternfly
  class Converter < ::Converter
    def initialize(repo: 'patternfly/patternfly', cache_path: 'tmp/converter-cache-patternfly')
      super(repo: repo, cache_path: cache_path)
      @save_to = { scss: 'sass' }
    end

    def process_patternfly
      log_status "Convert Patternfly LESS to SASS"
      puts " repo : #@repo_url"
      puts " branch : #@branch_sha #@repo_url/tree/#@branch"
      puts " save to: #{@save_to.to_json}"
      puts " twbs cache: #{@cache_path}"
      puts '-' * 60

      @save_to.values { |v| FileUtils.mkdir_p(v) }

      # process_font_assets
      process_patternfly_less_assets
      # process_javascript_assets
      # store_version
    end

    def process_patternfly_less_assets
      log_status "Processing stylesheets..."
      files = read_files('less', bootstrap_less_files)
      save_to = @save_to[:scss]
      files.each do |name, file|
        file = convert_less(file)
        name = name.sub(/\.less$/, '.scss')
        path = File.join(save_to, name)
        unless name == 'patternfly.scss'
          path = File.join(File.dirname(path), "_#{File.basename(path)}")
        end
        save_file(path, file)
        log_processed(File.basename(path))
      end
    end

    # Overrides super class method
    def bootstrap_less_files
      get_paths_by_type('less', /\.less$/)
    end

    def replace_file_imports(less, target_path='')
      super
      no_extension = %r([@\$]import ["|']([\w\-/]+)["|'];)
      less.gsub(no_extension, %Q(@import "#{target_path}\\1";))
    end
  end
end

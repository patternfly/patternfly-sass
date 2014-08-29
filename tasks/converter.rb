bootstrap_sass = Gem::Specification.find_by_name("bootstrap-sass").gem_dir
require "#{bootstrap_sass}/tasks/converter"

module Patternfly
  class Converter < ::Converter
    # Override
    def initialize(repo: 'patternfly/patternfly', cache_path: 'tmp/converter-cache-patternfly', branch: 'master', test_dir: 'tests/casperjs/patternfly')
      super(repo: repo, cache_path: cache_path)
      @save_to = { scss: 'sass' }
      @test_dir = test_dir
      get_trees('less', 'tests')
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
      store_version
      cache_tests
    end

    def process_patternfly_less_assets
      log_status "Processing stylesheets..."
      files = read_files('less', bootstrap_less_files)
      save_to = @save_to[:scss]
      files.each do |name, file|
        file = convert_less(file)
        name = name.sub(/\.less$/, '.scss')
        path = File.join(save_to, name)

        # Special cases go here
        case name
        when 'patternfly.scss'
          file = fix_top_level(file)
        end

        unless name == "patternfly.scss"
          path = File.join(File.dirname(path), "_#{File.basename(path)}")
        end

        save_file(path, file)
        log_processed(File.basename(path))
      end
    end

    def fix_top_level(file)
      patternfly_components = "../components/patternfly/components"
      file = replace_all(
        file,
        %r(../components/font-awesome/less/font-awesome),
        "#{patternfly_components}/font-awesome/scss/font-awesome")
      file = replace_all(
        file,
        %r(../components/bootstrap-select/bootstrap-select),
        "#{patternfly_components}/bootstrap-select/bootstrap-select"
      )
      file = replace_all(
        file,
        %r(../components/bootstrap/less/bootstrap),
        "../components/bootstrap-sass-official/vendor/assets/stylesheets/bootstrap")
      file
    end

    # Override
    def replace_file_imports(less, target_path='')
      less.gsub!(
        %r([@\$]import\s+(?:\(\w+\)\s+)?["|']([\w\-\./]+).less["|'];),
        %Q(@import "#{target_path}\\1";)
      )
      less.gsub!(
        %r([@\$]import\s+(?:\(\w+\)\s+)?["|']([\w\-\./]+).(css)["|'];),
        %Q(@import "#{target_path}\\1.\\2";)
      )
      less
    end

    def cache_tests
      test_files = get_paths_by_directory('tests')
      test_contents = read_files('tests', test_files)
      test_contents.each do |name, content|
        save_file(File.join(@test_dir, name), content)
      end
    end

    # Override
    def bootstrap_less_files
      get_paths_by_type('less', /\.less$/)
    end

    def store_version
      path = "package.json"
      content = File.read(path)
      # TODO read JSON and set correct version
      File.open(path, 'w') { |f| f.write(content) }
    end

    protected
    # Override
    def get_trees(*args)
      root = get_tree(@branch_sha)
      @tree_paths = {}
      args.each do |dir|
        dir_sha = get_tree_sha(dir, root)
        hash_list = []
        descend_tree(get_tree(dir_sha), dir, hash_list)
        dir_hash = hash_list.inject({}) do |memo, hash|
          memo.merge(hash)
        end
        @tree_paths.merge!(dir_hash)
      end
      @trees ||= @tree_paths.values
    end

    def descend_tree(tree, path, list)
      list << { path => tree }
      tree['tree'].map do |f|
        if f['type'] == 'tree'
          descend_tree(get_tree(f['sha']), File.join(path, f['path']), list)
        end
      end
    end

    # Override
    def get_paths_by_type(dir, regex)
      paths = get_paths_by_directory(dir)
      paths.select { |p| p =~ regex }
    end

    def get_paths_by_directory(dir)
      tree = @tree_paths[dir]
      if tree.nil?
        log_status("#{dir} not found in Git tree.")
        return []
      end

      files = tree['tree'].map do |f|
        case f['type']
        when 'blob'
          f['path']
        when 'tree'
          loc = File.join(dir, f['path'])
          {loc => get_paths_by_directory(loc)}
        end
      end
      files
    end

    # Override
    def read_files(path, files)
      hashes, strings = files.partition { |f| f.is_a?(Hash) }
      contents = {}
      contents = super(path, strings) unless strings.nil?
      hashes.each do |h|
        h.each do |k, v|
          contents.merge!(read_files(k, v))
        end
      end
      contents
    end
  end
end

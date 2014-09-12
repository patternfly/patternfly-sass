bootstrap_sass = Gem::Specification.find_by_name("bootstrap-sass").gem_dir
require "#{bootstrap_sass}/tasks/converter"

module Patternfly
  class Converter < ::Converter
    BOOTSTRAP_LESS_ROOT = 'components/bootstrap/less'
    PATTERNFLY_LESS_ROOT = 'less'

    # Override
    def initialize(repo: 'patternfly/patternfly', cache_path: 'tmp/converter-cache-patternfly', branch: 'master', test_dir: 'tests/casperjs/patternfly')
      super(repo: repo, cache_path: cache_path)
      @save_to = { scss: 'sass' }
      @test_dir = test_dir
      get_trees(PATTERNFLY_LESS_ROOT, BOOTSTRAP_LESS_ROOT, 'tests')
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
        # TODO unify with the case statement below.  Maybe pass in two procs as
        # callbacks; one for before and one for after.
        transforms = DEFAULT_TRANSFORMS
        case name
        when 'patternfly.less'
          transforms.reject! { |xform| xform == :replace_spin }
        when 'icons.less'
          transforms.reject! { |xform| xform == :replace_escaping }
        end

        file = convert_less(file, *transforms)

        # Special cases go here
        case name
        when 'mixins.less'
          file = replace_all(file,
            /,\s*\.open\s+\.dropdown-toggle& \{(.*?)\}/m,
            " {\\1}\n  .open & { &.dropdown-toggle {\\1} }")
        when 'icons.less'
          # Note the %q to prevent Ruby interpolation
          file = replace_all(file,
            %r#\.\$\{(icon-prefix)\}#,
            %q(#{$\\1}))
        when 'patternfly.less'
          file = fix_top_level(file)
        end

        name_out = "#{File.basename(name, ".less")}.scss"
        unless name_out == "patternfly.scss"
          name_out = "_#{name_out}"
        end

        path = File.join(save_to, name_out)
        save_file(path, file)
        log_processed(File.basename(path))
      end
    end

    def convert_less(less, *transforms)
      load_shared
      less = convert_to_scss(less, *transforms)
      less = yield(less) if block_given?
      less
    end

    DEFAULT_TRANSFORMS = [
      :replace_vars,
      :replace_file_imports,
      :replace_mixin_definitions,
      { :replace_mixins => ["mixins"] },
      :replace_spin,
      :replace_image_urls,
      :replace_image_urls,
      :replace_escaping,
      :convert_less_ampersand,
      :deinterpolate_vararg_mixins,
      :replace_calculation_semantics,
    ]

    def convert_to_scss(file, *transforms)
      mixins = @shared_mixins + read_mixins(file)
      transforms.each do |xform|
        args = ["file"]
        if xform.is_a?(Hash)
          args.concat(xform.values.first)
          xform = xform.keys.first
        end
        args.map! { |a| "#{eval a}" }
        file = send(xform, *args)
      end
      file
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
    # bootstrap-sass uses this method to read in all Bootstrap's less source files
    # We're going to repurpose it.
    def bootstrap_less_files
      patternfly_less_files
    end

    def patternfly_less_files
      get_paths_by_type('less', /\.less$/)
    end

    def load_shared
      mixin_hash = {}
      [BOOTSTRAP_LESS_ROOT, PATTERNFLY_LESS_ROOT].each do |root|
        log_status "Reading shared mixins from #{root}"
        mixin_hash[root] = read_files(root, get_paths_by_type(root, /mixins\.less$/)).values.join("\n")
      end
      @shared_mixins ||= begin
        read_mixins(mixin_hash.values.join("\n"), :nested => NESTED_MIXINS)
      end
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
      root = get_tree(@branch_sha)['sha']
      @tree_paths = {}
      args.each do |dir|
        path_components = dir.split('/')
        dir_sha = path_components.inject(root) do |tree_sha, component|
          tree_sha = get_tree_sha(component, get_tree(tree_sha))
        end
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

    def get_tree(sha)
      get_json("https://api.github.com/repos/#@repo/git/trees/#{sha}")
    end

    def get_tree_sha(dir, tree = get_trees)
      tree['tree'].find { |t| t['path'] == dir }['sha']
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

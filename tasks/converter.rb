BOOTSTRAP_GEM_ROOT = Gem::Specification.find_by_name("bootstrap-sass").gem_dir
require "#{BOOTSTRAP_GEM_ROOT}/tasks/converter"
require 'pathname'

module Patternfly
  class Converter < ::Converter
    BOOTSTRAP_LESS_ROOT = 'components/bootstrap/less'
    PATTERNFLY_LESS_ROOT = 'less'
    PATTERNFLY_COMPONENTS = "../components/patternfly/components"

    # Override
    def initialize(options)
      defaults = {
        :branch => 'master',
        :repo => 'patternfly/patternfly',
        :cache_path => 'tmp/converter-cache-patternfly',
        :test_dir => 'spec/html'
      }
      options = defaults.merge(options)
      super(:repo => options[:repo], :cache_path => options[:cache_path], :branch => options[:branch])
      @save_to = {
        :scss  => 'assets/stylesheets/patternfly',
        :js    => 'assets/javascripts',
        :fonts => 'assets/fonts/patternfly'
      }
      @test_dir = options[:test_dir]
      get_trees(PATTERNFLY_LESS_ROOT, BOOTSTRAP_LESS_ROOT, 'tests', 'dist')
    end

    def process_patternfly
      log_status "Convert Patternfly LESS to SASS"
      puts " repo : #@repo_url"
      puts " branch : #@branch_sha #@repo_url/tree/#@branch"
      puts " save to: #{@save_to.to_json}"
      puts " twbs cache: #{@cache_path}"
      puts '-' * 60

      @save_to.values { |v| FileUtils.mkdir_p(v) }

      process_font_assets
      process_patternfly_less_assets
      process_javascript_assets
      store_version
      cache_tests
    end

    def remove_xforms(transforms, *rejects)
      transforms.reject do |xform|
        rejects.include?(xform)
      end
    end

    def process_font_assets
      log_status 'Processing fonts...'
      files   = read_files(get_paths_by_type('dist/fonts', /\.(eot|svg|ttf|woff2?)$/))
      save_to = @save_to[:fonts]
      files.each do |name, content|
        save_file File.join(save_to, name.gsub('dist/fonts/', '')), content
      end
    end

    def process_javascript_assets
      log_status 'Processing javascripts...'
      save_to = @save_to[:js]
      files   = read_files(get_paths_by_type('dist/js', /\.js$/))
      files.each do |name, content|
        save_file File.join(save_to, name.gsub('dist/js/', '')), content
      end
    end

    def process_image_assets
      log_status 'Processing images...'
      save_to = @save_to[:img]
      files   = read_files(get_paths_by_type('dist/img', /\.(png|gif|jpg|svg?)$/))
      files.each do |name, content|
        save_file File.join(save_to, name.gsub('dist/img/', '')), content
      end
    end

    def process_patternfly_less_assets
      log_status "Processing stylesheets..."
      files = read_files(bootstrap_less_files)
      files['less/mixin_overrides.less'] = files['less/mixins.less'].dup
      # Merge the two separated top level files because they will be splitted on a higher level
      files['less/patternfly.less'] += files.delete('less/patternfly-additions.less')
      save_to = @save_to[:scss]

      files.each do |name, file|
        # TODO unify the case statements.  Maybe pass in two procs as
        # callbacks; one for before and one for after.
        #
        # TODO override replace_spin so its regex isn't so over-zealous
        transforms = DEFAULT_TRANSFORMS.dup
        name = File.basename(name)
        case name
        when 'mixin_overrides.less'
          button_variant = ".button-variant(.*?)"
          file = replace_rules(file, button_variant) do |rule, pos|
            ""
          end
        when 'patternfly.less', 'bootstrap-touchspin.less', 'variables.less'
          transforms = remove_xforms(transforms, :replace_spin)
        when 'spinner.less'
          transforms = remove_xforms(transforms, :replace_spin)
        end

        file = convert_less(file, *transforms)

        # Special cases go here
        case name
        when 'fonts.less', 'icons.less'
          file = replace_rules(file, /\s*@font-face/) do |rule|
            replace_asset_url rule, :font
          end
        when 'mixins.less'
          NESTED_MIXINS.each do |selector, prefix|
            file = flatten_mixins(file, selector, prefix)
          end
          file = replace_all(file, /,\s*\.open\s+\.dropdown-toggle& \{([^\{\}]*?)\}/m, " {\\1}\n  .open & { &.dropdown-toggle {\\1} }")
          file = replace_all(file, /,\s*\.open\s+\.dropdown-toggle& \{(.*?\{.*?\}.*?)\}/m, " {\\1}\n  .open & { &.dropdown-toggle {\\1} }")        when 'mixin_overrides.less'
          NESTED_MIXINS.each do |selector, prefix|
            file = flatten_mixins(file, selector, prefix)
          end
        when 'variables.less'
          file = insert_default_vars(file)
          file = ['$patternfly-sass-asset-helper: false !default;', file].join("\n")
          file = replace_all(file, %r{"../img"}, '"../images"')
          file = replace_all file, %r{(\$font-path): (\s*)"(.*)" (!default);}, '\\1: \\2if($patternfly-sass-asset-helper, "patternfly", "\\3/patternfly") \\4;'
          file = replace_all file, %r{(\$img-path): (\s*)"(.*)" (!default);}, '\\1: \\2if($patternfly-sass-asset-helper, "patternfly", "\\3/patternfly") \\4;'
          file = replace_all file, %r{(\$icon-font-path): (\s*)"(.*)" (!default);\n}, ''
          file = replace_all file, %r{(\$fa-font-path): (\s*)"(.*)" (!default);\n}, ''

        when 'patternfly.less'
          file = fix_top_level(file)
          add_to_dist('bootstrap-combobox')
          add_to_dist('bootstrap-select')
          # add_to_dist('bootstrap-switch')
          add_to_dist('bootstrap-touchspin', 'dist/jquery.bootstrap-touchspin')
          add_to_dist('bootstrap-datepicker', 'bootstrap-datepicker3')
          add_to_dist('c3')
        end

        name_out = "#{File.basename(name, ".less")}.scss"
        name_out = "_#{name_out}"

        path = File.join(save_to, name_out)
        save_file(path, file)
        log_processed(File.basename(path))
      end

      FileUtils.mv("#{save_to}/_patternfly.scss", File.expand_path("#{save_to}/../_patternfly.scss"))
    end

    # Load external components from rails-assets.org
    def add_to_dist(gemname, file=nil)
      file = "app/assets/stylesheets/#{gemname}/#{file.nil? ? gemname : file}.scss"
      in_file = File.join(Gem::Specification.find_by_name("rails-assets-#{gemname}").gem_dir, file)
      puts in_file
      out_file = File.join(@save_to[:scss], "_ext-#{gemname}.scss")
      FileUtils.cp(in_file, out_file)
      log_processed("Moving #{in_file} to #{out_file}")
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
      {:replace_mixins => ["mixins"]},
      :replace_spin,
      # :replace_fadein,
      :replace_image_urls,
      :replace_escaping,
      :convert_less_ampersand,
      :deinterpolate_vararg_mixins,
      :replace_calculation_semantics,
    ]

    def convert_to_scss(file, *transforms)
      # TODO The logging noop is to avoid a warning about an unused variable.
      # We actually are using mixins but we are reading it with an eval.
      # Possibly worth checking the arity of the method represented by xform
      # and send in variable in a defined order based on it? But that limits
      # us to a parameter order that every xform must follow.
      # Something like
      # params = [file, mixins]
      # arity = self.method(xform).arity
      # send(xform, *params[0..arity])
      mixins = @shared_mixins + read_mixins(file)
      silence_log do
        log_status(mixins)
      end
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
      file = replace_all(file, %r{@import\s+"variables";}, "")
      file = replace_all(file, /@import "([^\.]{2})/, '@import "patternfly/\1')
      file = replace_all(file, %r{../components/font-awesome/less/font-awesome}, "font-awesome")
      file = replace_all(file, %r{../components/bootstrap-select/less/bootstrap-select}, "patternfly/ext-bootstrap-select")
      file = replace_all(file, %r{../components/bootstrap-touchspin/dist/jquery.bootstrap-touchspin.css}, "patternfly/ext-bootstrap-touchspin")
      file = replace_all(file, %r{../components/bootstrap-switch/src/less/bootstrap3/bootstrap-switch}, "patternfly/ext-bootstrap-switch")
      file = replace_all(file, %r{@import\s+"../components/bootstrap/less/bootstrap";}, fetch_bootstrap_sass)
      file = replace_all(file, %r{../components/bootstrap-combobox/less/combobox}, "patternfly/ext-bootstrap-combobox")
      file = replace_all(file, %r{../components/bootstrap-datepicker/less/datepicker3}, "patternfly/ext-bootstrap-datepicker")
      file = replace_all(file, %r{../components/c3/c3.css}, "patternfly/ext-c3")


      # Remove undesired lines from the merged top level file
      file = replace_all(file, "@import \"../components/bootstrap/less/variables\";\n", "")
      file = replace_all(file, "// Bootstrap variables and mixins\n@import \"../components/bootstrap/less/mixins\";\n", "")
      file = replace_all(file, "// Font Awesome variables\n@import \"../components/font-awesome/less/variables\";\n", "")
      # Remove duplicate lines
      file = file.split("\n").uniq.join("\n").concat("\n")

      # Variables need to be declared before they are used.
      variables = <<-VAR.gsub(/^\s*/, '')
        @import "patternfly/variables";
        @import "bootstrap/variables";
      VAR
      variables + file
    end

    def fetch_bootstrap_sass
      bootstrap_sass = IO.read(File.join(BOOTSTRAP_GEM_ROOT, 'assets', 'stylesheets', '_bootstrap.scss'))

      bootstrap_sass = replace_all(
        bootstrap_sass,
        %r{@import\s+"bootstrap/variables";},
        ""
      )

      mixin_location = end_of(bootstrap_sass, %r{@import\s+"bootstrap/mixins";}).first
      bootstrap_sass = bootstrap_sass[0..mixin_location] + "@import \"patternfly/mixin_overrides\";\n" + bootstrap_sass[mixin_location..-1]
      bootstrap_sass
    end

    def end_of(s, regex)
      # Returns an array with the end position of each match
      s.enum_for(:scan, regex).map { Regexp.last_match.end(0) }
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

    # Override - bootstrap-sass doesn't handle cases where interpolation occurs outside
    # double quotes and removes the curly braces too early in the replace process.
    def replace_escaping(less)
     # Get rid of ~"" escape
     less = less.gsub(/~"([^"]+)"/, '#{\1}')
     # interpolate variable in string, e.g. url("$file-1x") => url("#{$file-1x}")
     less.gsub!(/\$\{([\w\-]+)\}/, '#{$\1}')
     # less.gsub!(/(?:"|')([^"'\n]*)(\$\{[\w\-]+\})([^"'\n]*)(?:"|')/, '"\1#{\2}\3"')
     # Get rid of @{} escape
     less.gsub!(/\$\{([^}]+)\}/, '$\1')
     # Get rid of e(%("")) escape
     less.gsub(/(\W)e\(%\("?([^"]*)"?\)\)/, '\1\2')
    end

    def cache_tests
      FileUtils.mkdir_p(@test_dir)
      test_files = get_paths_by_directory('tests')
      dist_files = get_paths_by_directory('dist/css')
      test_contents = read_files(test_files)
      dist_contents = fixup_path(read_files(dist_files))
      test_contents.merge(dist_contents).each do |file, content|
        # We go through all this rigmarole so we can save the tests and their
        # directory structure in a root of our choosing.
        top = ""
        # Get the top level directory
        Pathname.new(file).ascend do |v|
          top = v
        end
        # Get the filename below the top directory
        save_path = Pathname.new(file).relative_path_from(top).to_s

        # Create the correct destination
        save_path = File.join(@test_dir, save_path)
        unless File.directory?(File.dirname(save_path))
          FileUtils.mkdir_p(File.dirname(save_path))
        end
        save_file(save_path, content)
      end
    end

    def fixup_path(hash)
      Hash[hash.map { |k, v| ["dist/#{k}", v] }]
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
        mixin_hash[root] = read_files(
          get_paths_by_type(root, /mixins(\/)|(\.less)/)).values.join("\n")
      end
      @shared_mixins ||= begin
        read_mixins(mixin_hash.values.join("\n"), :nested => NESTED_MIXINS)
      end
    end

    def store_version
      path    = 'lib/patternfly-sass/version.rb'
      content = File.read(path).sub(/PATTERNFLY_SHA\s*=\s*['"][\w]+['"]/, "PATTERNFLY_SHA = '#@branch_sha'")
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
      list << {path => tree}
      tree['tree'].map do |f|
        if f['type'] == 'tree'
          descend_tree(get_tree(f['sha']), File.join(path, f['path']), list)
        end
      end
    end

    # Override
    def get_paths_by_type(base_dir, regex)
      paths = get_paths_by_directory(base_dir)

      # See http://stackoverflow.com/a/2698531 and http://stackoverflow.com/a/2552946
      matches = Hash.new do |h, key|
        h[key] = Array.new
      end

      paths.each do |dir, files|
        files.each do |f|
          matches[dir] << f if File.join(dir, f) =~ regex
        end
      end
      matches
    end

    def get_paths_by_directory(dir)
      tree = @tree_paths[dir]
      if tree.nil?
        log_status("#{dir} not found in Git tree.")
        return []
      end

      files = {}
      files[dir] = []
      tree['tree'].map do |f|
        case f['type']
        when 'blob'
          files[dir] << f['path']
        when 'tree'
          loc = File.join(dir, f['path'])
          files.merge!(get_paths_by_directory(loc))
        end
      end
      files
    end

    def get_tree(sha)
      get_json("https://api.github.com/repos/#@repo/git/trees/#{sha}")
    end

    def get_tree_sha(dir, tree=get_trees)
      tree['tree'].find { |t| t['path'] == dir }['sha']
    end

    # Override
    def read_files(files)
      contents = {}
      files.each do |dir, file|
        dir_contents = super(dir, file)
        full_path_contents = Hash[
          dir_contents.map do |k, v|
            [File.join(dir, k), v]
          end
        ]
        contents.merge!(full_path_contents)
      end
      contents
    end

    # Override
    def get_branch_sha
      @branch_sha ||= begin
        cmd = "git ls-remote #{Shellwords.escape "https://github.com/#@repo"} #@branch"
        log cmd
        result = %x[#{cmd}]
        raise 'Could not get branch sha!' unless $?.success? && !result.empty?
        result.split(/\s+/).first
      end
    end
  end
end

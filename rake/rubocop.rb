namespace :rubocop do
  def external_spec_files_octocatalog_diff
    Dir.chdir(BASEDIR) { Dir.glob('spec/octocatalog-diff/tests/external/**/*_spec.rb') }
  end

  def spec_files_octocatalog_diff
    Dir.chdir(BASEDIR) { Dir.glob('spec/octocatalog-diff/tests/**/*_spec.rb') } - external_spec_files_octocatalog_diff
  end

  def integration_files_octocatalog_diff
    Dir.chdir(BASEDIR) { Dir.glob('spec/octocatalog-diff/integration/**/*_spec.rb') }
  end

  def code_files_octocatalog_diff
    Dir.chdir(BASEDIR) { Dir.glob('lib/**/*.rb') } -
      Dir.chdir(BASEDIR) { Dir.glob('lib/octocatalog-diff/external/**/*.rb') }
  end

  def rake_files_octocatalog_diff
    result = Dir.chdir(BASEDIR) { Dir.glob('rake/**/*.rb') }
    result << 'Rakefile'
    result << 'octocatalog-diff.gemspec'
    result
  end

  task 'all' do
    files = code_files_octocatalog_diff +
            integration_files_octocatalog_diff +
            rake_files_octocatalog_diff +
            spec_files_octocatalog_diff
    abort unless system("#{BASEDIR}/script/fmt #{files.join(' ')}")
  end

  task 'code' do
    abort unless system("#{BASEDIR}/script/fmt #{code_files_octocatalog_diff.join(' ')}")
  end

  task 'integration' do
    abort unless system("#{BASEDIR}/script/fmt #{integration_files_octocatalog_diff.join(' ')}")
  end

  task 'rake' do
    abort unless system("#{BASEDIR}/script/fmt #{rake_files_octocatalog_diff.join(' ')}")
  end

  task 'spec' do
    abort unless system("#{BASEDIR}/script/fmt #{spec_files_octocatalog_diff.join(' ')}")
  end
end

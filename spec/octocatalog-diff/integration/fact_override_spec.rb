# frozen_string_literal: true

require_relative 'integration_helper'

require 'json'

describe 'fact override integration' do
  # The 'answer' to one of the tests below
  let(:foofoo_params) do
    {
      'type' => 'File',
      'title' => '/tmp/foofoo',
      'exported' => false,
      'parameters' => { 'content' => 'barbar' }
    }
  end

  context 'with parallel processing' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_repo: 'fact-overrides',
        spec_fact_file: 'valid-facts.yaml',
        argv: [
          '--to-fact-override', 'ipaddress=10.30.50.70',
          '--from-fact-override', 'foofoo=barbar',
          '--parallel'
        ]
      )
      @diffs = OctocatalogDiff::Spec.remove_file_and_line(@result[:diffs]).map do |x|
        x[2].delete('tags') if x[2].is_a?(Hash)
        x
      end
    end

    it 'should succeed' do
      expect(@result[:exitcode]).not_to eq(-1), "Internal error: #{@result[:exception]}\n#{@result[:logs]}"
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
    end

    it 'should show ip address change' do
      pending 'catalog-diff failed' unless @result[:exitcode] == 2
      this_diff = ['~', "File\f/tmp/ipaddress\fparameters\fcontent", '10.20.30.40', '10.30.50.70']
      expect(@diffs).to include(this_diff)
    end

    it 'should show foofoo removal' do
      pending 'catalog-diff failed' unless @result[:exitcode] == 2
      this_diff = ['-', "File\f/tmp/foofoo", foofoo_params]
      expect(@diffs).to include(this_diff)
    end

    it 'should show 2 diffs total' do
      pending 'catalog-diff failed' unless @result[:exitcode] == 2
      expect(@diffs.size).to eq(2)
    end
  end

  context 'with serial processing' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_repo: 'fact-overrides',
        spec_fact_file: 'valid-facts.yaml',
        argv: [
          '--to-fact-override', 'ipaddress=10.30.50.70',
          '--from-fact-override', 'foofoo=barbar',
          '--no-parallel'
        ]
      )
      @diffs = OctocatalogDiff::Spec.remove_file_and_line(@result[:diffs]).map do |x|
        x[2].delete('tags') if x[2].is_a?(Hash)
        x
      end
    end

    it 'should succeed' do
      expect(@result[:exitcode]).not_to eq(-1), "Internal error: #{@result[:exception]}\n#{@result[:logs]}"
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
    end

    it 'should show ip address change' do
      pending 'catalog-diff failed' unless @result[:exitcode] == 2
      this_diff = ['~', "File\f/tmp/ipaddress\fparameters\fcontent", '10.20.30.40', '10.30.50.70']
      expect(@diffs).to include(this_diff)
    end

    it 'should show foofoo removal' do
      pending 'catalog-diff failed' unless @result[:exitcode] == 2
      this_diff = ['-', "File\f/tmp/foofoo", foofoo_params]
      expect(@diffs).to include(this_diff)
    end

    it 'should show 2 diffs total' do
      pending 'catalog-diff failed' unless @result[:exitcode] == 2
      expect(@diffs.size).to eq(2)
    end
  end

  context 'with facts that have defined data types' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_repo: 'fact-overrides-datatypes',
        spec_fact_file: 'fact-overrides-datatypes.yaml',
        argv: [
          '--from-fact-override', 'my_boolean=true',
          '--from-fact-override', 'my_integer=42',
          '--from-fact-override', 'my_float=3.14159',
          '--from-fact-override', 'my_floating_integer=-100',
          '--from-fact-override', 'my_string=chicken',
          '--from-fact-override', 'my_json={"hello":"world"}',
          '--from-fact-override', 'my_boolean_string=false',
          '--from-fact-override', 'my_integer_string=42',
          '--from-fact-override', 'my_float_string=3.14159',
          '--to-fact-override', 'my_boolean=(boolean)true',
          '--to-fact-override', 'my_integer=(fixnum)42',
          '--to-fact-override', 'my_float=(float)3.14159',
          '--to-fact-override', 'my_floating_integer=(float)-100',
          '--to-fact-override', 'my_string=(string)chicken',
          '--to-fact-override', 'my_json=(json){"hello":"world"}',
          '--to-fact-override', 'my_boolean_string=(string)false',
          '--to-fact-override', 'my_integer_string=(string)42',
          '--to-fact-override', 'my_float_string=(string)3.14159'
        ]
      )
      @diffs = OctocatalogDiff::Spec.remove_file_and_line(@result[:diffs])
    end

    it 'should succeed' do
      expect(@result[:exitcode]).not_to eq(-1), "Internal error: #{@result[:exception]}\n#{@result[:logs]}"
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
      expect(@diffs.size).to eq(1)
    end

    it 'should show the guessed data types in the original catalog' do
      pending 'catalog-diff failed' unless @result[:exitcode] == 2 && @diffs.size == 1
      file = @diffs[0][2].split(/\n/)
      expect(file).to include('my_boolean: TrueClass true')
      expect(file).to include('my_integer: Fixnum 42')
      expect(file).to include('my_float: Float 3.14159')
      expect(file).to include('my_floating_integer: Integer -100')
      expect(file).to include('my_json: String "{\\"hello\\":\\"world\\"}"')
      expect(file).to include('my_boolean_string: FalseClass false')
      expect(file).to include('my_integer_string: Integer 42')
      expect(file).to include('my_float_string: Float 3.14159')
      expect(file).to include('real_boolean: FalseClass false')
      expect(file).to include('real_float: Float 3.14159')
      expect(file).to include('real_integer: Integer 42')
      expect(file).to include('real_string: String "chicken"')
    end

    it 'should show the specified data types in the new catalog' do
      pending 'catalog-diff failed' unless @result[:exitcode] == 2 && @diffs.size == 1
      file = @diffs[0][3].split(/\n/)
      expect(file).to include('my_boolean: TrueClass true')
      expect(file).to include('my_integer: Fixnum 42')
      expect(file).to include('my_float: Float 3.14159')
      expect(file).to include('my_floating_integer: Float -100.0')
      expect(file).to include('my_json: Hash {"hello"=>"world"}')
      expect(file).to include('my_boolean_string: String "false"')
      expect(file).to include('my_integer_string: String "42"')
      expect(file).to include('my_float_string: String "3.14159"')
      expect(file).to include('real_boolean: FalseClass false')
      expect(file).to include('real_float: Float 3.14159')
      expect(file).to include('real_integer: Fixnum 42')
      expect(file).to include('real_string: String "chicken"')
    end
  end
end

describe 'fact override via CLI' do
  before(:all) do
    @result = OctocatalogDiff::Integration.integration_cli(
      [
        '-n', 'rspec-node.github.net',
        '--bootstrapped-to-dir', OctocatalogDiff::Spec.fixture_path('repos/fact-overrides'),
        '--bootstrapped-from-dir', OctocatalogDiff::Spec.fixture_path('repos/fact-overrides'),
        '--to-fact-override', 'ipaddress=10.30.50.70',
        '--from-fact-override', 'foofoo=barbar',
        '--output-format', 'json',
        '--fact-file', OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'),
        '--puppet-binary', OctocatalogDiff::Spec::PUPPET_BINARY,
        '-d'
      ]
    )
  end

  it 'should exit with status 2' do
    expect(@result.exitcode).to eq(2), @result.stderr
  end

  it 'should contain the correct diffs' do
    parse_result = JSON.parse(@result.stdout)['diff'].map { |x| OctocatalogDiff::Spec.remove_file_and_line(x) }
    expect(parse_result.size).to eq(2)
    expect(parse_result).to include(
      'diff_type' => '~',
      'type' => 'File',
      'title' => '/tmp/ipaddress',
      'structure' => %w(parameters content),
      'old_value' => '10.20.30.40',
      'new_value' => '10.30.50.70'
    )
    expect(parse_result).to include(
      'diff_type' => '-',
      'type' => 'File',
      'title' => '/tmp/foofoo',
      'structure' => [],
      'old_value' => {
        'type' => 'File',
        'title' => '/tmp/foofoo',
        'tags' => %w(class default file node test),
        'exported' => false,
        'parameters' => { 'content' => 'barbar' }
      },
      'new_value' => nil
    )
  end

  it 'should log the correct messages' do
    expect(@result.stderr).to match(/Catalog for . will be built with OctocatalogDiff::Catalog::Computed/)
    expect(@result.stderr).to match(/Override ipaddress from "10.20.30.40" to "10.30.50.70"/)
    expect(@result.stderr).to match(/Override foofoo from nil to "barbar"/)
    expect(@result.stderr).to match(/Diffs computed for rspec-node.github.net/)
  end
end

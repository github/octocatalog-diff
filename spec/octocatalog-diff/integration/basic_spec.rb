# frozen_string_literal: true

require_relative 'integration_helper'

describe 'a basic integration test' do
  context 'with no changes' do
    context 'and a v4 target catalog' do
      before(:all) do
        @result = OctocatalogDiff::Integration.integration(
          spec_repo_old: 'default',
          spec_fact_file: 'facts.yaml',
          output_format: :json,
          argv: [
            '--to-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/default-catalog-v4.json'),
            '--hiera-config', 'environments/production/config/hiera.yaml',
            '--hiera-path-strip', '/var/lib/puppet'
          ]
        )
      end

      it 'should run without an error' do
        expect(@result[:exitcode]).not_to eq(-1), "Internal error: #{OctocatalogDiff::Integration.format_exception(@result)}"
        expect(@result[:exitcode]).to eq(0), "Runtime error: #{@result[:logs]}"
      end

      it 'should have no changes' do
        pending 'catalog-diff failed' unless (@result[:exitcode]).zero?
        diffs = OctocatalogDiff::Spec.remove_file_and_line(@result[:diffs])
        expect(diffs.size).to eq(0), diffs.map(&:inspect).join("\n")
      end
    end

    context 'and a v3 target catalog' do
      before(:all) do
        @result = OctocatalogDiff::Integration.integration(
          spec_repo_old: 'default',
          spec_fact_file: 'facts.yaml',
          output_format: :json,
          argv: [
            '--to-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/default-catalog-v3.json'),
            '--hiera-config', 'environments/production/config/hiera.yaml',
            '--hiera-path-strip', '/var/lib/puppet'
          ]
        )
      end

      it 'should run without an error' do
        expect(@result[:exitcode]).not_to eq(-1), "Internal error: #{OctocatalogDiff::Integration.format_exception(@result)}"
        expect(@result[:exitcode]).to eq(0), "Runtime error: #{@result[:logs]}"
      end

      it 'should have no changes' do
        pending 'catalog-diff failed' unless (@result[:exitcode]).zero?
        diffs = OctocatalogDiff::Spec.remove_file_and_line(@result[:diffs])
        expect(diffs.size).to eq(0), diffs.map(&:inspect).join("\n")
      end
    end
  end

  context 'with changes' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_repo_new: 'default',
        spec_fact_file: 'facts.yaml',
        output_format: :json,
        argv: [
          '--from-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/default-catalog-changed.json'),
          '--hiera-config', 'environments/production/config/hiera.yaml',
          '--hiera-path-strip', '/var/lib/puppet'
        ]
      )
      @diffs = OctocatalogDiff::Spec.remove_file_and_line(@result[:diffs]).map do |x|
        x[2].delete('tags') if x[2].is_a?(Hash)
        x
      end
    end

    it 'should run without an error' do
      expect(@result[:exitcode]).not_to eq(-1), "Internal error: #{OctocatalogDiff::Integration.format_exception(@result)}"
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
    end

    it 'should have the correct changes' do
      pending 'catalog-diff failed' unless @result[:exitcode] == 2
      expect(@diffs).to include(['~', "File\f/root/.ssh\fparameters\fgroup", 'wheel', 'root'])
      expect(@diffs).to include(
        [
          '!',
          "System::Root_ssh_key\fAAAAB3NzaC1yc2EAAAADAQABAAAAYQDR8yC4LVV3e8lyl6USr3DmNahuEVcDIIy/ILH09/s2UVXG3k1fjYyBJYaAcbaws2bZj2ilhYxeTbeC2uRgeQDCq+9yRZE07Frf7BWExIFChgy5mpxZ2gIDrBhEZjwEaoE=\fparameters", # rubocop:disable Metrics/LineLength
          { 'blah' => 'Foo' },
          nil
        ]
      )
      expect(@diffs).to include(['~', "System::User\falice\fparameters\fcomment", 'Alice Jones', 'Alice Smith'])
      expect(@diffs).to include(
        [
          '+',
          "Ssh_authorized_key\froot@6def27049c06f48eea8b8f37329f40799d07dc84",
          {
            'type' => 'Ssh_authorized_key',
            'title' => 'root@6def27049c06f48eea8b8f37329f40799d07dc84',
            'exported' => false,
            'parameters' => {
              'user' => 'root',
              'type' => 'ssh-rsa',
              'key' => 'AAAAB3NzaC1yc2EAAAADAQABAAAAYQDWi50hxBpNRIoBHylzXkARdWJAHRRDqD7vLY1AdXTvBed7dHVt0XK99zSaYWV1xo+p94W9PdQyp3hrSQtifK8zL5g0pvCHal4JODo7FNHreJDJZCguV41OviM/7jdVBAs=' # rubocop:disable Metrics/LineLength
            }
          }
        ]
      )
      expect(@diffs).to include(
        [
          '-',
          "Group\fbill",
          { 'type' => 'Group', 'title' => 'bill', 'exported' => false, 'parameters' => { 'ensure' => 'present', 'gid' => 1551 } }
        ]
      )
      expect(@diffs).to include(['!', "Ssh_authorized_key\fbob@local\fparameters\ffoo", 'bar', nil])
      expect(@diffs).to include(['!', "Ssh_authorized_key\fbob@local\fparameters\ftype", nil, 'ssh-rsa'])
      expect(@diffs.size).to eq(7), @diffs.map(&:inspect).join("\n")
    end
  end
end

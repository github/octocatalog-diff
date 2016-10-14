require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_pass_env_vars' do
    it 'should add one pass environment variable' do
      result = run_optparse(['--pass-env-vars', 'FOO'])
      expect(result[:pass_env_vars]).to eq(%w(FOO))
    end

    it 'should add multiple pass environment variables' do
      result = run_optparse(['--pass-env-vars', 'FOO,BAR'])
      expect(result[:pass_env_vars]).to eq(%w(FOO BAR))
    end

    it 'should add multiple pass environment variable with multiple flags' do
      result = run_optparse(['--pass-env-vars', 'FOO', '--pass-env-vars', 'BAR'])
      expect(result[:pass_env_vars]).to eq(%w(FOO BAR))
    end
  end
end

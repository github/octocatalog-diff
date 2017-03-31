# frozen_string_literal: true

require_relative '../spec_helper'

require OctocatalogDiff::Spec.require_path('catalog-util/git')
require OctocatalogDiff::Spec.require_path('errors')
require OctocatalogDiff::Spec.require_path('util/scriptrunner')

require 'ostruct'

describe OctocatalogDiff::CatalogUtil::Git do
  before(:each) do
    @logger, @logger_str = OctocatalogDiff::Spec.setup_logger
    allow(File).to receive(:'directory?').with('/tmp/foo').and_return(false)
    allow(File).to receive(:'directory?').with('/tmp/bar').and_return(true)
  end

  describe '#check_out_git_archive' do
    context 'with invalid directory' do
      it 'should raise OctocatalogDiff::Errors::GitCheckoutError if basedir is nil' do
        opts = { branch: 'foo', path: '/tmp/foo', basedir: nil, logger: @logger }
        expect do
          described_class.check_out_git_archive(opts)
        end.to raise_error(OctocatalogDiff::Errors::GitCheckoutError, /Source directory/)
      end

      it 'should raise OctocatalogDiff::Errors::GitCheckoutError if basedir does not exist' do
        opts = { branch: 'foo', path: '/tmp/foo', basedir: '/tmp/foo', logger: @logger }
        expect do
          described_class.check_out_git_archive(opts)
        end.to raise_error(OctocatalogDiff::Errors::GitCheckoutError, /Source directory/)
      end

      it 'should raise OctocatalogDiff::Errors::GitCheckoutError if path is nil' do
        opts = { branch: 'foo', path: nil, basedir: '/tmp/bar', logger: @logger }
        expect do
          described_class.check_out_git_archive(opts)
        end.to raise_error(OctocatalogDiff::Errors::GitCheckoutError, /Target directory/)
      end

      it 'should raise OctocatalogDiff::Errors::GitCheckoutError if path does not exist' do
        opts = { branch: 'foo', path: '/tmp/foo', basedir: '/tmp/bar', logger: @logger }
        expect do
          described_class.check_out_git_archive(opts)
        end.to raise_error(OctocatalogDiff::Errors::GitCheckoutError, /Target directory/)
      end
    end

    context 'with valid directory' do
      context 'with successful script run' do
        it 'should log proper messages and not raise error' do
          script_runner = double
          expect(script_runner).to receive(:run).and_return('')
          expect(OctocatalogDiff::Util::ScriptRunner).to receive(:new).and_return(script_runner)

          opts = { branch: 'foo', path: '/tmp/bar', basedir: '/tmp/bar', logger: @logger }
          described_class.check_out_git_archive(opts)
          expect(@logger_str.string).to match(%r{Success git archive /tmp/bar:foo})
        end
      end

      context 'with failed script run' do
        it 'should raise OctocatalogDiff::Errors::GitCheckoutError' do
          script_runner = double
          expect(script_runner).to receive(:run).and_raise(OctocatalogDiff::Util::ScriptRunner::ScriptException)
          expect(script_runner).to receive(:output).and_return('errors abound')
          expect(OctocatalogDiff::Util::ScriptRunner).to receive(:new).and_return(script_runner)

          opts = { branch: 'foo', path: '/tmp/bar', basedir: '/tmp/bar', logger: @logger }
          expect do
            described_class.check_out_git_archive(opts)
          end.to raise_error(OctocatalogDiff::Errors::GitCheckoutError, 'Git archive foo->/tmp/bar failed: errors abound')
        end
      end
    end
  end

  describe '#branch_sha' do
    context 'with invalid directory' do
      it 'should raise Errno::ENOENT if basedir is nil' do
        opts = { branch: 'foo', basedir: nil }
        expect do
          described_class.branch_sha(opts)
        end.to raise_error(Errno::ENOENT, /Git directory/)
      end

      it 'should raise Errno::ENOENT if basedir does not exist' do
        opts = { branch: 'foo', basedir: '/tmp/foo' }
        expect do
          described_class.branch_sha(opts)
        end.to raise_error(Errno::ENOENT, /Git directory/)
      end
    end

    context 'with valid directory' do
      it 'should return the sha from rugged' do
        opts = { branch: 'foo', basedir: '/tmp/bar' }
        expect(Rugged::Repository).to receive(:new).with('/tmp/bar')
          .and_return(OpenStruct.new(branches: { 'foo' => OpenStruct.new(target_id: 'abcdef012345') }))
        result = described_class.branch_sha(opts)
        expect(result).to eq('abcdef012345')
      end
    end
  end
end

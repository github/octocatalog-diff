# frozen_string_literal: true

require_relative '../spec_helper'

require OctocatalogDiff::Spec.require_path('catalog-util/git')
require OctocatalogDiff::Spec.require_path('errors')

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
          expect(described_class).to receive(:create_git_checkout_script).and_return('/tmp/baz.sh')
          expect(Open3).to receive(:capture2e)
            .with('/tmp/baz.sh', chdir: '/tmp/bar')
            .and_return(['asldfkj', OpenStruct.new(exitstatus: 0)])
          opts = { branch: 'foo', path: '/tmp/bar', basedir: '/tmp/bar', logger: @logger }
          described_class.check_out_git_archive(opts)
          expect(@logger_str.string).to match(%r{Success git archive /tmp/bar:foo})
        end
      end

      context 'with failed script run' do
        it 'should raise OctocatalogDiff::Errors::GitCheckoutError' do
          expect(described_class).to receive(:create_git_checkout_script).and_return('/tmp/baz.sh')
          expect(Open3).to receive(:capture2e)
            .with('/tmp/baz.sh', chdir: '/tmp/bar')
            .and_return(['errors abound', OpenStruct.new(exitstatus: 1)])
          opts = { branch: 'foo', path: '/tmp/bar', basedir: '/tmp/bar', logger: @logger }
          expect do
            described_class.check_out_git_archive(opts)
          end.to raise_error(OctocatalogDiff::Errors::GitCheckoutError, 'Git archive foo->/tmp/bar failed: errors abound')
        end
      end
    end
  end

  describe '#create_git_checkout_script' do
    it 'should create the temporary script' do
      result = described_class.create_git_checkout_script('foo', '/tmp/baz')
      expect(result).to be_a_kind_of(String)
      expect(File.file?(result)).to eq(true)

      text = File.read(result)
      expect(text).to match(/git archive --format=tar foo \|/)
      expect(text).to match(%r{\( cd /tmp/baz && tar -xf - \)})

      expect(File.executable?(result)).to eq(true)
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

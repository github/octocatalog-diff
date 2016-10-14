require_relative '../../spec_helper'
require OctocatalogDiff::Spec.require_path('/catalog-util/enc/pe')
require OctocatalogDiff::Spec.require_path('/catalog-util/facts')
require OctocatalogDiff::Spec.require_path('/facts')

describe OctocatalogDiff::CatalogUtil::ENC::PE do
  describe '#new' do
    it 'should error if node is not specified' do
      opts = { pe_enc_url: 'https://localhost:4433/classifier-api' }
      expect { OctocatalogDiff::CatalogUtil::ENC::PE.new(opts) }.to raise_error(ArgumentError, /requires :node/)
    end

    it 'should error if URL is not specified' do
      opts = { node: 'foo' }
      expect { OctocatalogDiff::CatalogUtil::ENC::PE.new(opts) }.to raise_error(ArgumentError, /requires :pe_enc_url/)
    end
  end

  describe '#content' do
    it 'should return nil on an unexecuted object' do
      opts = { node: 'foo', pe_enc_url: 'https://localhost:4433/classifier-api' }
      testobj = OctocatalogDiff::CatalogUtil::ENC::PE.new(opts)
      expect(testobj.content).to eq(nil)
    end
  end

  describe '#error_message' do
    it 'should return expected message on an unexecuted object' do
      opts = { node: 'foo', pe_enc_url: 'https://localhost:4433/classifier-api' }
      testobj = OctocatalogDiff::CatalogUtil::ENC::PE.new(opts)
      expect(testobj.error_message).to eq('The execute method was never run')
    end
  end

  context 'when fact retrieval succeeds' do
    before(:each) do
      @logger, @logger_str = OctocatalogDiff::Spec.setup_logger

      fact_obj = double('OctocatalogDiff::CatalogUtil::Facts')
      unless @facts
        facts_opts = {
          node: 'rspec-node.github.net',
          backend: :yaml,
          fact_file_string: OctocatalogDiff::Spec.fixture_read('facts/valid-facts.yaml')
        }
        @facts = OctocatalogDiff::Facts.new(facts_opts)
      end
      allow(fact_obj).to receive(:facts).and_return(@facts)
      allow(OctocatalogDiff::CatalogUtil::Facts).to receive(:new).and_return(fact_obj)
    end

    context 'with valid response from Puppet Enterprise ENC' do
      before(:each) do
        content = {
          code: 200,
          parsed: {
            'classes' => { 'foo' => {} },
            'parameters' => { 'test::test_param' => 'test_param' }
          }
        }
        allow(OctocatalogDiff::Util::HTTParty).to receive(:post).and_return(content)

        opts = { node: 'foo', pe_enc_url: 'https://localhost:4433/classifier-api' }
        @testobj = OctocatalogDiff::CatalogUtil::ENC::PE.new(opts)
        @testobj.execute(@logger)
      end

      describe '#execute' do
        it 'should set content to YAML representation' do
          result = @testobj.content
          expect(result).to eq("---\nclasses:\n  foo: {}\nparameters:\n  test::test_param: test_param\n")
        end

        it 'should set error message to nil' do
          result = @testobj.error_message
          expect(result).to eq(nil)
        end

        it 'should log the expected messages' do
          log = @logger_str.string
          expect(log).to match(/DEBUG.+Beginning OctocatalogDiff::CatalogUtil::ENC::PE#execute for foo/)
          expect(log).to match(/DEBUG.+Start retrieving facts for foo from OctocatalogDiff::CatalogUtil::ENC::PE/)
          expect(log).to match(/DEBUG.+Success retrieving facts for foo from OctocatalogDiff::CatalogUtil::ENC::PE/)
          expect(log).to match(/DEBUG.+Response from https:.+ was 200/)
          expect(log).to match(/DEBUG.+Completed OctocatalogDiff::CatalogUtil::ENC::PE#execute for foo/)
        end
      end
    end

    context 'with error response from Puppet Enterprise ENC' do
      context 'result code != 200' do
        describe '#execute' do
          before(:each) do
            content = {
              code: 401,
              body: 'Authentication required'
            }
            allow(OctocatalogDiff::Util::HTTParty).to receive(:post).and_return(content)

            opts = { node: 'foo', pe_enc_url: 'https://localhost:4433/classifier-api' }
            @testobj = OctocatalogDiff::CatalogUtil::ENC::PE.new(opts)
            @testobj.execute(@logger)
          end

          it 'should set content to nil' do
            expect(@testobj.content).to eq(nil)
          end

          it 'should set error message' do
            answer = 'Response from https://localhost:4433/classifier-api/v1/classified/nodes/foo was 401'
            expect(@testobj.error_message).to eq(answer)
          end

          it 'should log messages' do
            log = @logger_str.string
            expect(log).to match(/DEBUG.+Beginning OctocatalogDiff::CatalogUtil::ENC::PE#execute for foo/)
            expect(log).to match(/DEBUG.+Start retrieving facts for foo from OctocatalogDiff::CatalogUtil::ENC::PE/)
            expect(log).to match(/DEBUG.+Success retrieving facts for foo from OctocatalogDiff::CatalogUtil::ENC::PE/)
            expect(log).to match(/DEBUG.+PE ENC failed: \{:code=>401, :body=>"Authentication required"\}/)
            expect(log).to match(/ERROR.+PE ENC failed: Response from https:.+ was 401/)
          end
        end
      end

      context 'error message with 200' do
        describe '#execute' do
          before(:each) do
            content = {
              code: 200,
              body: '{"error": "No data was found for this node"}',
              parsed: { 'error' => 'No data was found for this node' }
            }
            allow(OctocatalogDiff::Util::HTTParty).to receive(:post).and_return(content)

            opts = { node: 'foo', pe_enc_url: 'https://localhost:4433/classifier-api' }
            @testobj = OctocatalogDiff::CatalogUtil::ENC::PE.new(opts)
            @testobj.execute(@logger)
          end

          it 'should set content to nil' do
            expect(@testobj.content).to eq(nil)
          end

          it 'should set error message' do
            answer = 'Response missing: classes'
            expect(@testobj.error_message).to eq(answer)
          end

          it 'should log messages' do
            log = @logger_str.string
            expect(log).to match(/DEBUG.+Beginning OctocatalogDiff::CatalogUtil::ENC::PE#execute for foo/)
            expect(log).to match(/DEBUG.+Start retrieving facts for foo from OctocatalogDiff::CatalogUtil::ENC::PE/)
            expect(log).to match(/DEBUG.+Success retrieving facts for foo from OctocatalogDiff::CatalogUtil::ENC::PE/)
            expect(log).to match(/DEBUG.+Response from https:.+ was 200/)
            expect(log).to match(/ERROR.+PE ENC failed: Response missing: classes/)
          end
        end
      end

      context 'bad data' do
        describe '#execute' do
          before(:each) do
            content = {
              code: 200,
              body: 'something went terribly wrong'
            }
            allow(OctocatalogDiff::Util::HTTParty).to receive(:post).and_return(content)

            opts = { node: 'foo', pe_enc_url: 'https://localhost:4433/classifier-api' }
            @testobj = OctocatalogDiff::CatalogUtil::ENC::PE.new(opts)
            @testobj.execute(@logger)
          end

          it 'should set content to nil' do
            expect(@testobj.content).to eq(nil)
          end

          it 'should set error message' do
            expect(@testobj.error_message).to match(/PE ENC failed: Response from https:.+ was not a hash! NilClass/)
          end

          it 'should log messages' do
            log = @logger_str.string
            expect(log).to match(/DEBUG.+Beginning OctocatalogDiff::CatalogUtil::ENC::PE#execute for foo/)
            expect(log).to match(/DEBUG.+Start retrieving facts for foo from OctocatalogDiff::CatalogUtil::ENC::PE/)
            expect(log).to match(/DEBUG.+Success retrieving facts for foo from OctocatalogDiff::CatalogUtil::ENC::PE/)
            expect(log).to match(/DEBUG.+Response from https:.+ was 200/)
            expect(log).to match(/ERROR.+PE ENC failed: Response from https:.+foo was not a hash! nil/)
          end
        end
      end
    end
  end

  context 'when fact retrieval fails' do
    describe '#execute' do
      before(:each) do
        @logger, @logger_str = OctocatalogDiff::Spec.setup_logger

        fact_obj = double('OctocatalogDiff::CatalogUtil::Facts')
        allow(fact_obj).to receive(:facts).and_raise(OctocatalogDiff::Facts::FactRetrievalError, 'Fact Error')
        allow(OctocatalogDiff::CatalogUtil::Facts).to receive(:new).and_return(fact_obj)

        opts = { node: 'foo', pe_enc_url: 'https://localhost:4433/classifier-api' }
        @testobj = OctocatalogDiff::CatalogUtil::ENC::PE.new(opts)
        @testobj.execute(@logger)
      end

      it 'should set content to nil' do
        expect(@testobj.content).to eq(nil)
      end

      it 'should set error message' do
        answer = 'Fact retrieval failed: OctocatalogDiff::Facts::FactRetrievalError - Fact Error'
        expect(@testobj.error_message).to eq(answer)
      end

      it 'should log messages' do
        log = @logger_str.string
        expect(log).to match(/DEBUG.+Beginning OctocatalogDiff::CatalogUtil::ENC::PE#execute for foo/)
        expect(log).to match(/DEBUG.+Start retrieving facts for foo from OctocatalogDiff::CatalogUtil::ENC::PE/)
        expect(log).to match(/ERROR.+Fact retrieval failed: OctocatalogDiff::Facts::FactRetrievalError - Fact Error/)
      end
    end
  end
end

require_relative '../spec_helper'
require OctocatalogDiff::Spec.require_path('/util/parallel')
require 'logger'
require 'parallel'

# rubocop:disable Style/GlobalVars
describe OctocatalogDiff::Util::Parallel do
  before(:each) do
    $octocatalog_diff_util_parallel_spec_tempdir = Dir.mktmpdir
  end

  after(:each) do
    OctocatalogDiff::Spec.clean_up_tmpdir($octocatalog_diff_util_parallel_spec_tempdir)
  end

  context 'with parallel processing' do
    it 'should parallelize and return task results' do
      class Foo
        def one(arg, _logger = nil)
          ['one', arg, Process.pid].join(' ')
        end

        def two(arg, _logger = nil)
          ['two', arg, Process.pid].join(' ')
        end
      end

      c = Foo.new
      one = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:one), args: 'abc', description: 'test one')
      two = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:two), args: 'def', description: 'test two')
      result = OctocatalogDiff::Util::Parallel.run_tasks([one, two], nil, true)
      expect(result).to be_a_kind_of(Array)
      expect(result.size).to eq(2)

      one_result = result[0]
      expect(one_result).to be_a_kind_of(OctocatalogDiff::Util::Parallel::Result)
      expect(one_result.status).to eq(true)
      expect(one_result.exception).to eq(nil)
      expect(one_result.output).to match(/^one abc /)

      two_result = result[1]
      expect(two_result).to be_a_kind_of(OctocatalogDiff::Util::Parallel::Result)
      expect(two_result.status).to eq(true)
      expect(two_result.exception).to eq(nil)
      expect(two_result.output).to match(/^two def /)

      # Process ID should be difference since the tasks are supposed to be forked
      one_pid = one_result.output.split(/\s+/).last
      two_pid = two_result.output.split(/\s+/).last
      expect(one_pid).not_to be_nil
      expect(one_pid).not_to eq(two_pid)
    end

    it 'should handle a task that fails after other successes' do
      class Foo
        def one(arg, _logger = nil)
          File.open(File.join($octocatalog_diff_util_parallel_spec_tempdir, 'one'), 'w') { |f| f.write '' }
          'one ' + arg
        end

        def two(_arg, _logger = nil)
          100.times do
            break if File.file?(File.join($octocatalog_diff_util_parallel_spec_tempdir, 'one'))
            sleep 0.1
          end
          raise 'Two failed'
        end
      end

      c = Foo.new
      one = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:one), args: 'abc', description: 'test one')
      two = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:two), args: 'def', description: 'test two')
      result = OctocatalogDiff::Util::Parallel.run_tasks([one, two], nil, true)
      expect(result).to be_a_kind_of(Array)
      expect(result.size).to eq(2)

      one_result = result[0]
      expect(one_result).to be_a_kind_of(OctocatalogDiff::Util::Parallel::Result)
      expect(one_result.status).to eq(true)
      expect(one_result.exception).to eq(nil)
      expect(one_result.output).to eq('one abc')

      two_result = result[1]
      expect(two_result).to be_a_kind_of(OctocatalogDiff::Util::Parallel::Result)
      expect(two_result.status).to eq(false)
      expect(two_result.exception).to be_a_kind_of(RuntimeError)
      expect(two_result.exception.message).to eq('Two failed')
    end

    it 'should kill running tasks when one task fails' do
      class Foo
        def one(arg, _logger = nil)
          sleep 10
          File.open(File.join($octocatalog_diff_util_parallel_spec_tempdir, 'one'), 'w') { |f| f.write '' }
          'one ' + arg
        end

        def two(_arg, _logger = nil)
          raise 'Two failed'
        end
      end

      c = Foo.new
      one = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:one), args: 'abc', description: 'test one')
      two = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:two), args: 'def', description: 'test two')
      result = OctocatalogDiff::Util::Parallel.run_tasks([one, two], nil, true)
      expect(result).to be_a_kind_of(Array)
      expect(result.size).to eq(2)

      one_result = result[0]
      expect(one_result).to be_a_kind_of(OctocatalogDiff::Util::Parallel::Result)
      expect(one_result.status).to eq(nil)
      expect(one_result.exception).to be_a_kind_of(::Parallel::Kill)
      expect(one_result.exception.message).to eq('Killed')
      expect(one_result.output).to eq(nil)

      two_result = result[1]
      expect(two_result).to be_a_kind_of(OctocatalogDiff::Util::Parallel::Result)
      expect(two_result.status).to eq(false)
      expect(two_result.exception).to be_a_kind_of(RuntimeError)
      expect(two_result.exception.message).to eq('Two failed')

      expect(File.file?(File.join($octocatalog_diff_util_parallel_spec_tempdir, 'one'))).to eq(false)
    end

    it 'should log debug messages' do
      class Foo
        def my_method(arg, _logger = nil)
          arg
        end
      end

      c = Foo.new
      one = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:my_method), args: 'abc', description: 'test one')
      expect do
        logger = Logger.new(STDERR)
        OctocatalogDiff::Util::Parallel.run_tasks([one], logger, true)
      end.to output(/DEBUG.*Begin test one/).to_stderr_from_any_process

      expect do
        logger = Logger.new(STDERR)
        OctocatalogDiff::Util::Parallel.run_tasks([one], logger, true)
      end.to output(/DEBUG.*Success test one/).to_stderr_from_any_process
    end

    it 'should log error messages' do
      class Foo
        def my_method(arg, _logger = nil)
          raise arg
        end
      end

      c = Foo.new
      one = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:my_method), args: 'abc', description: 'test one')
      two = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:my_method), args: 'def', description: 'test two')
      expect do
        logger = Logger.new(STDERR)
        OctocatalogDiff::Util::Parallel.run_tasks([one, two], logger, true)
      end.to output(/DEBUG.*Begin test (one|two)/).to_stderr_from_any_process

      expect do
        logger = Logger.new(STDERR)
        OctocatalogDiff::Util::Parallel.run_tasks([one, two], logger, true)
      end.to output(/DEBUG.*Failed test (one|two): RuntimeError (abc|def)/).to_stderr_from_any_process
    end

    it 'should return empty array when no tasks are passed' do
      result = OctocatalogDiff::Util::Parallel.run_tasks([], nil, true)
      expect(result).to eq([])
    end

    it 'should validate results when a validator method is provided' do
      class Foo
        def one(arg, _logger = nil)
          'one ' + arg
        end

        def two(arg, _logger = nil)
          'two ' + arg
        end

        def validate(arg, _logger = nil)
          arg =~ /^one/ || arg =~ /^two/ ? true : false
        end
      end

      c = Foo.new
      v = c.method(:validate)
      one = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:one), args: 'abc', description: 'test one', validator: v)
      two = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:two), args: 'def', description: 'test two', validator: v)
      result = OctocatalogDiff::Util::Parallel.run_tasks([one, two], nil, true)
      expect(result).to be_a_kind_of(Array)
      expect(result.size).to eq(2)

      expect(result[0].status).to eq(true)
      expect(result[1].status).to eq(true)
    end

    it 'should recognize invalid results when a validator method is provided' do
      class Foo
        def one(arg, _logger = nil)
          'one ' + arg
        end

        def two(arg, _logger = nil)
          sleep 1
          'two ' + arg
        end

        def validate(arg, _logger = nil)
          arg =~ /^one/ ? true : false
        end
      end

      c = Foo.new
      v = c.method(:validate)
      one = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:one), args: 'abc', description: 'test one', validator: v)
      two = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:two), args: 'def', description: 'test two', validator: v)
      result = OctocatalogDiff::Util::Parallel.run_tasks([one, two], nil, true)
      expect(result).to be_a_kind_of(Array)
      expect(result.size).to eq(2)

      expect(result[0].status).to eq(true)
      expect(result[1].status).to eq(false)
    end

    it 'should kill other tasks when a validator method fails' do
      class Foo
        def one(arg, _logger = nil)
          sleep 10
          'one ' + arg
        end

        def two(arg, _logger = nil)
          'two ' + arg
        end

        def validate(arg, _logger = nil)
          arg =~ /^one/ ? true : false
        end
      end

      c = Foo.new
      v = c.method(:validate)
      one = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:one), args: 'abc', description: 'test one', validator: v)
      two = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:two), args: 'def', description: 'test two', validator: v)
      result = OctocatalogDiff::Util::Parallel.run_tasks([one, two], nil, true)
      expect(result).to be_a_kind_of(Array)
      expect(result.size).to eq(2)

      expect(result[0].status).to eq(nil)
      expect(result[1].status).to eq(false)
    end
  end

  context 'with serial processing' do
    it 'should perform tasks' do
      class Foo
        def one(arg, _logger = nil)
          'one ' + arg + ' ' + Time.now.to_i.to_s
        end

        def two(arg, _logger = nil)
          sleep 1
          'two ' + arg + ' ' + Time.now.to_i.to_s
        end
      end

      c = Foo.new
      one = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:one), args: 'abc', description: 'test one')
      two = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:two), args: 'def', description: 'test two')
      result = OctocatalogDiff::Util::Parallel.run_tasks([one, two], nil, false)
      expect(result).to be_a_kind_of(Array)
      expect(result.size).to eq(2)

      one_result = result[0]
      expect(one_result).to be_a_kind_of(OctocatalogDiff::Util::Parallel::Result)
      expect(one_result.status).to eq(true)
      expect(one_result.exception).to eq(nil)
      expect(one_result.output).to match(/^one abc \d+$/)

      two_result = result[1]
      expect(two_result).to be_a_kind_of(OctocatalogDiff::Util::Parallel::Result)
      expect(two_result.status).to eq(true)
      expect(two_result.exception).to eq(nil)
      expect(two_result.output).to match(/^two def \d+$/)

      one_time = Regexp.last_match(1).to_i if one_result.output =~ /(\d+)$/
      two_time = Regexp.last_match(1).to_i if two_result.output =~ /(\d+)$/
      expect(one_time).to be < two_time
    end

    it 'should handle a task that fails after other successes' do
      class Foo
        def one(arg, _logger = nil)
          'one ' + arg
        end

        def two(_arg, _logger = nil)
          raise 'Two failed'
        end
      end

      c = Foo.new
      one = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:one), args: 'abc', description: 'test one')
      two = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:two), args: 'def', description: 'test two')
      result = OctocatalogDiff::Util::Parallel.run_tasks([one, two], nil, false)
      expect(result).to be_a_kind_of(Array)
      expect(result.size).to eq(2)

      one_result = result[0]
      expect(one_result).to be_a_kind_of(OctocatalogDiff::Util::Parallel::Result)
      expect(one_result.status).to eq(true)
      expect(one_result.exception).to eq(nil)
      expect(one_result.output).to eq('one abc')

      two_result = result[1]
      expect(two_result).to be_a_kind_of(OctocatalogDiff::Util::Parallel::Result)
      expect(two_result.status).to eq(false)
      expect(two_result.exception).to be_a_kind_of(RuntimeError)
      expect(two_result.exception.message).to eq('Two failed')
    end

    it 'should not perform tasks once one fails' do
      class Foo
        def one(_arg, _logger = nil)
          raise 'One failed'
        end

        def two(arg, _logger = nil)
          'two ' + arg
        end
      end

      c = Foo.new
      one = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:one), args: 'abc', description: 'test one')
      two = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:two), args: 'def', description: 'test two')
      result = OctocatalogDiff::Util::Parallel.run_tasks([one, two], nil, false)
      expect(result).to be_a_kind_of(Array)
      expect(result.size).to eq(2)

      one_result = result[0]
      expect(one_result).to be_a_kind_of(OctocatalogDiff::Util::Parallel::Result)
      expect(one_result.status).to eq(false)
      expect(one_result.exception).to be_a_kind_of(::RuntimeError)
      expect(one_result.exception.message).to eq('One failed')
      expect(one_result.output).to eq(nil)

      two_result = result[1]
      expect(two_result).to be_a_kind_of(OctocatalogDiff::Util::Parallel::Result)
      expect(two_result.status).to eq(nil)
      expect(two_result.exception).to be_a_kind_of(::RuntimeError)
      expect(two_result.exception.message).to eq('Cancellation - A prior task failed')
    end

    it 'should log debug messages' do
      class Foo
        def my_method(arg, _logger = nil)
          arg
        end
      end

      c = Foo.new
      one = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:my_method), args: 'abc', description: 'test one')
      logger, logger_string = OctocatalogDiff::Spec.setup_logger
      OctocatalogDiff::Util::Parallel.run_tasks([one], logger, false)
      expect(logger_string.string).to match(/DEBUG.*Begin test one/)
      expect(logger_string.string).to match(/DEBUG.*Success test one/)
    end

    it 'should log error messages' do
      class Foo
        def my_method(arg, _logger = nil)
          raise arg
        end
      end

      c = Foo.new
      one = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:my_method), args: 'abc', description: 'test one')
      two = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:my_method), args: 'def', description: 'test two')
      logger, logger_string = OctocatalogDiff::Spec.setup_logger
      OctocatalogDiff::Util::Parallel.run_tasks([one, two], logger, false)
      expect(logger_string.string).to match(/DEBUG.*Begin test one/)
      expect(logger_string.string).to match(/DEBUG.*Failed test one: RuntimeError abc/)
    end

    it 'should return empty array when no tasks are passed' do
      result = OctocatalogDiff::Util::Parallel.run_tasks([], nil, false)
      expect(result).to eq([])
    end

    it 'should validate results when a validator method is provided' do
      class Foo
        def one(arg, _logger = nil)
          'one ' + arg
        end

        def two(arg, _logger = nil)
          'two ' + arg
        end

        def validate(arg, _logger = nil)
          arg =~ /^one/ || arg =~ /^two/ ? true : false
        end
      end

      c = Foo.new
      v = c.method(:validate)
      one = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:one), args: 'abc', description: 'test one', validator: v)
      two = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:two), args: 'def', description: 'test two', validator: v)
      result = OctocatalogDiff::Util::Parallel.run_tasks([one, two], nil, false)
      expect(result).to be_a_kind_of(Array)
      expect(result.size).to eq(2)

      expect(result[0].status).to eq(true)
      expect(result[1].status).to eq(true)
    end

    it 'should recognize invalid results when a validator method is provided' do
      class Foo
        def one(arg, _logger = nil)
          'one ' + arg
        end

        def two(arg, _logger = nil)
          'two ' + arg
        end

        def validate(arg, _logger = nil)
          arg =~ /^one/ ? true : false
        end
      end

      c = Foo.new
      v = c.method(:validate)
      one = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:one), args: 'abc', description: 'test one', validator: v)
      two = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:two), args: 'def', description: 'test two', validator: v)
      result = OctocatalogDiff::Util::Parallel.run_tasks([one, two], nil, false)
      expect(result).to be_a_kind_of(Array)
      expect(result.size).to eq(2)

      expect(result[0].status).to eq(true)
      expect(result[1].status).to eq(false)
    end

    it 'should not perform subsequent tasks when a validator method fails' do
      class Foo
        def one(arg, _logger = nil)
          'one ' + arg
        end

        def two(arg, _logger = nil)
          'two ' + arg
        end

        def validate(arg, _logger = nil)
          arg =~ /^one/ ? false : true
        end
      end

      c = Foo.new
      v = c.method(:validate)
      one = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:one), args: 'abc', description: 'test one', validator: v)
      two = OctocatalogDiff::Util::Parallel::Task.new(method: c.method(:two), args: 'def', description: 'test two', validator: v)
      result = OctocatalogDiff::Util::Parallel.run_tasks([one, two], nil, false)
      expect(result).to be_a_kind_of(Array)
      expect(result.size).to eq(2)

      expect(result[0].status).to eq(false)
      expect(result[1].status).to eq(nil)
    end
  end

  describe '#run_tasks' do
    it 'should raise ArgumentError when passed something that is not a task' do
      not_a_task = double('foo')
      task_array = [not_a_task]
      expect do
        OctocatalogDiff::Util::Parallel.run_tasks(task_array)
      end.to raise_error(ArgumentError, /Element .* must be a OctocatalogDiff::Util::Parallel::Task, not a /)
    end
  end
end
# rubocop:enable Style/GlobalVars

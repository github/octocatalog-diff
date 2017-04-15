# frozen_string_literal: true

require_relative '../../spec_helper'
require OctocatalogDiff::Spec.require_path('/catalog-diff/display/text')

describe OctocatalogDiff::CatalogDiff::Display::Text do
  before(:all) do
    @separator = '*' * 43
  end

  #
  # Begin tests for options that can be passed
  #

  context 'Options' do
    before(:all) do
      loc_map = { 'file' => '/environments/production/modules/puppet/manifests/filename.pp', 'line' => 42 }
      @top_level_add_1 = ['+', "Foo\fBar", { 'text' => 'this was added at the top level' }, loc_map]
      @top_level_rem_1 = ['-', "Foo\fBar", { 'text' => 'this was removed at the top level' }, loc_map]
      @top_level_chg_1 = ['~', "Foo\fBar\fBaz", 'old', 'new', loc_map, loc_map]
      @nested_chg_1 = ['!', "Foo\fBar\fBaz\fBoo", 'old', 'new', loc_map, loc_map]
      @multiline_string_diff = ['~', "Foo\fBar\fBaz", "One\nTwo\nThree\nFive", "One\nThree\nFour\nFive", loc_map, loc_map]
    end

    context 'source file location' do
      describe '#generate' do
        it 'should display location info for addition' do
          diff = [@top_level_add_1]
          options = { color: false, display_source_file_line: true, compilation_to_dir: '/environments/production' }
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result[0]).to eq('  modules/puppet/manifests/filename.pp:42')
          expect(result[1]).to eq('+ Foo[Bar]')
        end

        it 'should display location info for removal' do
          diff = [@top_level_rem_1]
          options = { color: false, display_source_file_line: true, compilation_from_dir: '/environments/production' }
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result[0]).to eq('  modules/puppet/manifests/filename.pp:42')
          expect(result[1]).to eq('- Foo[Bar]')
        end

        it 'should display location info for change' do
          diff = [@top_level_chg_1]
          options = { color: false, display_source_file_line: true, compilation_from_dir: '/environments/production' }
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result[0]).to eq('  modules/puppet/manifests/filename.pp:42')
          expect(result[1]).to eq('  Foo[Bar] =>')
          expect(result[2]).to eq('   Baz =>')
          expect(result[3]).to eq('    - old')
          expect(result[4]).to eq('    + new')
        end

        it 'should display location info for nested change' do
          diff = [@nested_chg_1]
          options = { color: false, display_source_file_line: true, compilation_from_dir: '/environments/production' }
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result[0]).to eq('  modules/puppet/manifests/filename.pp:42')
          expect(result[1]).to eq('  Foo[Bar] =>')
          expect(result[2]).to eq('   Baz =>')
          expect(result[3]).to eq('     Boo =>')
          expect(result[4]).to eq('      - old')
          expect(result[5]).to eq('      + new')
        end

        it 'should not display location info if it is empty' do
          diff = [@nested_chg_1.dup]
          diff[0][4] = { 'file' => nil, 'line' => nil }
          diff[0][5] = { 'file' => nil, 'line' => nil }
          options = { color: false, display_source_file_line: true, compilation_from_dir: '/environments/production' }
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result[0]).to eq('  Foo[Bar] =>')
        end

        it 'should display old location if new location is empty' do
          diff = [@nested_chg_1.dup]
          diff[0][4] = { 'file' => 'modules/puppet/manifests/old-filename.pp', 'line' => 367 }
          diff[0][5] = { 'file' => nil, 'line' => nil }
          options = { color: false, display_source_file_line: true, compilation_from_dir: '/environments/production' }
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result[0]).to eq('  modules/puppet/manifests/old-filename.pp:367')
        end

        it 'should display new location if old location is empty' do
          diff = [@nested_chg_1.dup]
          diff[0][4] = { 'file' => nil, 'line' => nil }
          diff[0][5] = { 'file' => 'modules/puppet/manifests/new-filename.pp', 'line' => 251 }
          options = { color: false, display_source_file_line: true, compilation_from_dir: '/environments/production' }
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result[0]).to eq('  modules/puppet/manifests/new-filename.pp:251')
        end

        it 'should display just one location if locations match' do
          diff = [@nested_chg_1.dup]
          diff[0][4] = { 'file' => 'modules/puppet/manifests/filename.pp', 'line' => 353 }
          diff[0][5] = { 'file' => 'modules/puppet/manifests/filename.pp', 'line' => 353 }
          options = { color: false, display_source_file_line: true, compilation_from_dir: '/environments/production' }
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result[0]).to eq('  modules/puppet/manifests/filename.pp:353')
        end

        it 'should display both locations if they do not match' do
          diff = [@nested_chg_1.dup]
          diff[0][4] = { 'file' => 'modules/puppet/manifests/old-filename.pp', 'line' => 2345 }
          diff[0][5] = { 'file' => 'modules/puppet/manifests/new-filename.pp', 'line' => 3425 }
          options = { color: false, display_source_file_line: true, compilation_from_dir: '/environments/production' }
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result[0]).to eq('- modules/puppet/manifests/old-filename.pp:2345')
          expect(result[1]).to eq('+ modules/puppet/manifests/new-filename.pp:3425')
          expect(result[2]).to eq('  Foo[Bar] =>')
        end
      end
    end

    context 'color' do
      describe '#generate' do
        it 'should disable color in colorize when :color => false' do
          diff = [@top_level_add_1]
          options = { color: false }
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result.first).to eq('+ Foo[Bar]')
        end

        it 'should enable color in colorize when :color => false' do
          diff = [@top_level_add_1]
          options = { color: true }
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result.first).to eq("\e[0;32;49m+ Foo[Bar]\e[0m")
        end

        it 'should enable color in colorize when :color is not specified' do
          diff = [@top_level_add_1]
          options = {}
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result.first).to eq("\e[0;32;49m+ Foo[Bar]\e[0m")
        end

        it 'should disable color in diffy when :color => false' do
          diff = [@multiline_string_diff]
          options = { color: false }
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result).to include('    @@ -1,4 +1,4 @@')
          expect(result.join('')).not_to match(/\e/)
        end

        it 'should enable color in diffy when :color => true' do
          diff = [@multiline_string_diff]
          options = { color: true }
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result).to include("    \e[36m@@ -1,4 +1,4 @@\e[0m")
        end

        it 'should enable color in diffy when :color is not specified' do
          diff = [@multiline_string_diff]
          options = {}
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result).to include("    \e[36m@@ -1,4 +1,4 @@\e[0m")
        end
      end
    end

    context 'header' do
      describe '#generate' do
        it 'should print a header when a header is specified' do
          diff = [@top_level_add_1]
          options = { header: 'This is my header' }
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result.first).to eq('This is my header')
          expect(result[1]).to match(/^\*+$/)
        end

        it 'should not print a header when header is nil' do
          diff = [@top_level_add_1]
          options = { header: nil }
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result.first).to eq("\e[0;32;49m+ Foo[Bar]\e[0m")
        end

        it 'should not print a header when header is undefined' do
          diff = [@top_level_add_1]
          options = {}
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result.first).to eq("\e[0;32;49m+ Foo[Bar]\e[0m")
        end

        it 'should not print a header (or anything else) when there is no diff' do
          diff = []
          options = { header: 'This is my header' }
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result.size).to eq(0)
        end

        it 'should not print an empty header' do
          diff = [@top_level_add_1]
          options = { header: '' }
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, options)
          expect(result.first).to match(/^\*+$/)
        end
      end
    end
  end

  #
  # Begin tests for diff output
  #

  context 'Diff output' do
    context 'resources added at top level' do
      context 'with display_detail_add off' do
        describe '#generate' do
          it 'should display a single diff' do
            diff = [
              ['+', "Foo\fBar", { 'text' => 'this was added at the top level' }]
            ]
            answer = [
              'header',
              @separator,
              "\e[0;32;49m+ Foo[Bar]\e[0m",
              @separator
            ]
            result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: true, header: 'header')
            expect(result).to eq(answer)
          end

          it 'should display two diffs separated by a separator' do
            diff = [
              ['+', "Foo\fBar", { 'text' => 'this was added at the top level' }],
              ['+', "Foo\fBaz", { 'text' => 'so was this' }]
            ]
            answer = [
              'header',
              @separator,
              "\e[0;32;49m+ Foo[Bar]\e[0m",
              @separator,
              "\e[0;32;49m+ Foo[Baz]\e[0m",
              @separator
            ]
            result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: true, header: 'header')
            expect(result).to eq(answer)
          end
        end
      end

      context 'with display_detail_add' do
        before(:all) do
          @diff = [
            [
              '+',
              'File[/tmp/foo]',
              {
                'type' => 'File',
                'title' => '/tmp/foo',
                'parameters' => {
                  'mode' => '0644',
                  'content' => 'x' * 150,
                  'owner' => 'root',
                  'group' => 'wheel'
                }
              }
            ]
          ]
        end

        context 'with --no-truncate-details' do
          describe '#generate' do
            before(:all) do
              @result = OctocatalogDiff::CatalogDiff::Display::Text.generate(
                @diff,
                display_detail_add: true,
                color: false,
                truncate_details: false
              )
            end

            it 'should not truncate long strings' do
              expect(@result[2]).to match(/^\s+"content": /)
              expect(@result[2].length).to eq(169), "Wrong line length for: '#{@result[2]}': #{@result[2].length}"
            end
          end
        end

        context 'with --no-truncate-details and a multi-line string' do
          describe '#generate' do
            before(:all) do
              diff = [
                [
                  '+',
                  'File[/tmp/foo]',
                  {
                    'type' => 'File',
                    'title' => '/tmp/foo',
                    'parameters' => {
                      'mode' => '0644',
                      'content' => "foo\nbar\nbaz",
                      'owner' => 'root',
                      'group' => 'wheel'
                    }
                  }
                ]
              ]
              @result = OctocatalogDiff::CatalogDiff::Display::Text.generate(
                diff,
                display_detail_add: true,
                color: false,
                truncate_details: false
              )
            end

            it 'should sort keys without newlines before keys with newlines' do
              expect(@result[2]).to match(/^\s+"group": /)
              expect(@result[3]).to match(/^\s+"mode": /)
              expect(@result[4]).to match(/^\s+"owner": /)
            end

            it 'should display lines on their own' do
              expect(@result[5]).to match(/^\s+"content": >>>/)
              expect(@result[6]).to eq('foo')
              expect(@result[7]).to eq('bar')
              expect(@result[8]).to eq('baz')
              expect(@result[9]).to eq('<<<')
            end
          end
        end

        context 'without --no-truncate-details' do
          describe '#generate' do
            before(:all) do
              @result = OctocatalogDiff::CatalogDiff::Display::Text.generate(@diff, display_detail_add: true, color: false)
            end

            it 'should display parameters when display_detail_add is true' do
              expect(@result[1]).to match(/^\s+parameters =>/)
            end

            it 'should truncate long strings' do
              expect(@result[2]).to match(/^\s+"content": /)
              # Desired line length is 84 because the '..."' adds 4 characters to the truncated length of 80
              expect(@result[2].length).to eq(84), "Wrong line length for: '#{@result[2]}'"
            end

            it 'should sort keys in parameters hash' do
              index_content = @result.find_index { |x| x =~ /^\s+"content": / }
              expect(index_content).not_to be(nil), 'Results missing "content"'
              index_group = @result.find_index { |x| x =~ /^\s+"group": / }
              expect(index_group).not_to be(nil), 'Results missing "group"'
              index_mode = @result.find_index { |x| x =~ /^\s+"mode": / }
              expect(index_mode).not_to be(nil), 'Results missing "mode"'
              index_owner = @result.find_index { |x| x =~ /^\s+"owner": / }
              expect(index_owner).not_to be(nil), 'Results missing "owner"'
              expect(index_content).to be < index_group
              expect(index_group).to be < index_mode
              expect(index_mode).to be < index_owner
            end
          end
        end
      end
    end

    context 'resources removed at top level' do
      describe '#generate' do
        it 'should display a single diff' do
          diff = [
            ['-', "Foo\fBar", { 'text' => 'this was added at the top level' }]
          ]
          answer = [
            'header',
            @separator,
            "\e[0;31;49m- Foo[Bar]\e[0m",
            @separator
          ]
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: true, header: 'header')
          expect(result).to eq(answer)
        end

        it 'should display two diffs separated by a separator' do
          diff = [
            ['-', "Foo\fBar", { 'text' => 'this was added at the top level' }],
            ['-', "Foo\fBaz", { 'text' => 'so was this' }]
          ]
          answer = [
            'header',
            @separator,
            "\e[0;31;49m- Foo[Bar]\e[0m",
            @separator,
            "\e[0;31;49m- Foo[Baz]\e[0m",
            @separator
          ]
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: true, header: 'header')
          expect(result).to eq(answer)
        end
      end
    end

    context 'change to a single line string' do
      describe '#generate' do
        it 'should display correctly when a string has changed' do
          diff = [
            ['~', "Foo\fBar\fbaz\fbuzz", 'old string', 'new string']
          ]
          answer = [
            'header',
            @separator,
            '  Foo[Bar] =>',
            '   baz =>',
            '     buzz =>',
            "      \e[31m- old string\e[0m",
            "      \e[32m+ new string\e[0m",
            @separator
          ]
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: true, header: 'header')
          expect(result).to eq(answer)
        end
      end
    end

    context 'change to a multi-line string' do
      describe '#generate' do
        it 'should display correctly when a multi-line string has entirely changed' do
          diff = [
            ['~', "Foo\fBar\fbaz\fbuzz", "old string\nold string 2\n", "new string\nnew string 2\n"]
          ]
          answer = [
            'header',
            @separator,
            '  Foo[Bar] =>',
            '   baz =>',
            '     buzz =>',
            "      \e[36m@@ -1,2 +1,2 @@\e[0m",
            "      \e[31m-old string\e[0m",
            "      \e[31m-old string 2\e[0m",
            "      \e[32m+new string\e[0m",
            "      \e[32m+new string 2\e[0m",
            @separator
          ]
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: true, header: 'header')
          expect(result).to eq(answer)
        end

        it 'should display correctly when a multi-line string has partially changed' do
          diff = [
            ['~', "Foo\fBar\fbaz\fbuzz", "old string\ncommon\nold string 2\n", "new string\ncommon\nnew string 2\n"]
          ]
          answer = [
            'header',
            @separator,
            '  Foo[Bar] =>',
            '   baz =>',
            '     buzz =>',
            "      \e[36m@@ -1,3 +1,3 @@\e[0m",
            "      \e[31m-old string\e[0m",
            "      \e[32m+new string\e[0m",
            '       common',
            "      \e[31m-old string 2\e[0m",
            "      \e[32m+new string 2\e[0m",
            @separator
          ]
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: true, header: 'header')
          expect(result).to eq(answer)
        end

        it 'should display correctly when one string is single line and the other is multi-line' do
          diff = [
            ['~', "Foo\fBar\fbaz\fbuzz", 'old string', "new string\nnew string 2\n"]
          ]
          answer = [
            'header',
            @separator,
            '  Foo[Bar] =>',
            '   baz =>',
            '     buzz =>',
            "      \e[36m@@ -1 +1,2 @@\e[0m",
            "      \e[31m-old string\e[0m",
            '      \\ No newline at end of file',
            "      \e[32m+new string\e[0m",
            "      \e[32m+new string 2\e[0m",
            @separator
          ]
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: true, header: 'header')
          expect(result).to eq(answer)
        end
      end
    end

    context 'change to a number' do
      describe '#generate' do
        it 'should display correctly when both old and new are numbers' do
          diff = [
            ['~', "Foo\fBar\fbaz\fbuzz", 1, 42]
          ]
          answer = [
            'header',
            @separator,
            '  Foo[Bar] =>',
            '   baz =>',
            '     buzz =>',
            "\e[0;31;49m      - 1\e[0m",
            "\e[0;32;49m      + 42\e[0m",
            @separator
          ]
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: true, header: 'header')
          expect(result).to eq(answer)
        end

        it 'should display correctly if a number changed to a string' do
          diff = [
            ['~', "Foo\fBar\fbaz\fbuzz", 1, 'forty-two']
          ]
          answer = [
            'header',
            @separator,
            '  Foo[Bar] =>',
            '   baz =>',
            '     buzz =>',
            "\e[0;31;49m      - 1\e[0m",
            "\e[0;32;49m      + forty-two\e[0m",
            @separator
          ]
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: true, header: 'header')
          expect(result).to eq(answer)
        end
      end
    end

    context 'change to a boolean' do
      describe '#generate' do
        it 'should display correctly when both old and new are booleans' do
          diff = [
            ['~', "Foo\fBar\fbaz\fbuzz", true, false]
          ]
          answer = [
            'header',
            @separator,
            '  Foo[Bar] =>',
            '   baz =>',
            '     buzz =>',
            "\e[0;31;49m      - true\e[0m",
            "\e[0;32;49m      + false\e[0m",
            @separator
          ]
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: true, header: 'header')
          expect(result).to eq(answer)
        end

        it 'should display correctly if a boolean changed to a string' do
          diff = [
            ['~', "Foo\fBar\fbaz\fbuzz", true, 'forty-two']
          ]
          answer = [
            'header',
            @separator,
            '  Foo[Bar] =>',
            '   baz =>',
            '     buzz =>',
            "\e[0;31;49m      - true\e[0m",
            "\e[0;32;49m      + forty-two\e[0m",
            @separator
          ]
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: true, header: 'header')
          expect(result).to eq(answer)
        end
      end
    end

    context 'change of keys in a nested hash' do
      describe '#generate' do
        it 'should display correctly when something is added to a hash' do
          diff = [
            ['!', "Foo\fBar\fbaz\fbuzz", nil, { 'fizz' => 'fizz-value' }]
          ]
          answer = [
            'header',
            @separator,
            '  Foo[Bar] =>',
            '   baz =>',
            '     buzz =>',
            "\e[0;32;49m      + {\"fizz\"=>\"fizz-value\"}\e[0m",
            @separator
          ]
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: true, header: 'header')
          expect(result).to eq(answer)
        end

        it 'should display correctly when something is removed from a hash' do
          diff = [
            ['!', "Foo\fBar\fbaz\fbuzz", { 'fizz' => 'fizz-value' }, nil]
          ]
          answer = [
            'header',
            @separator,
            '  Foo[Bar] =>',
            '   baz =>',
            '     buzz =>',
            "\e[0;31;49m      - {\"fizz\"=>\"fizz-value\"}\e[0m",
            @separator
          ]
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: true, header: 'header')
          expect(result).to eq(answer)
        end

        it 'should display correctly when something is changed within a hash' do
          diff = [
            ['!', "Foo\fBar\fbaz\fbuzz", { 'fizz' => 'fizz-value' }, { 'fizz' => 'new-value' }]
          ]
          answer = [
            'header',
            @separator,
            '  Foo[Bar] =>',
            '   baz =>',
            '     buzz =>',
            "      \e[31m-  \"fizz\": \"fizz-value\"\e[0m",
            "      \e[32m+  \"fizz\": \"new-value\"\e[0m",
            @separator
          ]
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: true, header: 'header')
          expect(result).to eq(answer)
        end
      end
    end

    context 'change in elements of a nested array' do
      describe '#generate' do
        it 'should display correctly when something is added to an array' do
          diff = [
            ['!', "Foo\fBar\fbaz\fbuzz", nil, [1, 2, 3]]
          ]
          answer = [
            'header',
            @separator,
            '  Foo[Bar] =>',
            '   baz =>',
            '     buzz =>',
            "\e[0;32;49m      + [1, 2, 3]\e[0m",
            @separator
          ]
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: true, header: 'header')
          expect(result).to eq(answer)
        end

        it 'should display correctly when something is removed from an array' do
          diff = [
            ['!', "Foo\fBar\fbaz\fbuzz", [1, 2, 3], nil]
          ]
          answer = [
            'header',
            @separator,
            '  Foo[Bar] =>',
            '   baz =>',
            '     buzz =>',
            "\e[0;31;49m      - [1, 2, 3]\e[0m",
            @separator
          ]
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: true, header: 'header')
          expect(result).to eq(answer)
        end

        it 'should display correctly when an array changes' do
          diff = [
            ['!', "Foo\fBar\fbaz\fbuzz", [1, 2, 3, 4], [1, 1, 2, 3, 5]]
          ]
          answer = [
            'header',
            @separator,
            '  Foo[Bar] =>',
            '   baz =>',
            '     buzz =>',
            "\e[0;31;49m      - [1, 2, 3, 4]\e[0m",
            "\e[0;32;49m      + [1, 1, 2, 3, 5]\e[0m",
            @separator
          ]
          result = OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: true, header: 'header')
          expect(result).to eq(answer)
        end
      end
    end

    context 'display datatype changes' do
      let(:diff) { JSON.parse(File.read(OctocatalogDiff::Spec.fixture_path('diffs/string-equality.json'))) }

      context 'with display_datatype_changes off' do
        describe '#adjust_for_display_datatype_changes' do
          # Must be :each not :all because diff resets between each test
          before(:each) do
            OctocatalogDiff::CatalogDiff::Display::Text.adjust_for_display_datatype_changes(diff, false)
          end

          it 'should return an array of the correct size' do
            # Since all of the other items were deleted and we explicitly test the
            # remaining item in the next test, it's not necessary to test the removal
            # of each other element.
            expect(diff.size).to eq(3)
          end

          it 'should pass back different integers' do
            expect(diff[0][2]).to eq(12_345)
            expect(diff[0][3]).to eq(67_890)
          end

          it 'should pass back nil versus a value' do
            expect(diff[1][2]).to eq(nil)
            expect(diff[1][3]).to eq(67_890)
          end

          it 'should pass back a value versus nil' do
            expect(diff[2][2]).to eq(12_345)
            expect(diff[2][3]).to eq(nil)
          end
        end
      end

      context 'with display_datatype_changes on' do
        describe '#adjust_for_display_datatype_changes' do
          # Must be :each not :all because diff resets between each test
          before(:each) do
            OctocatalogDiff::CatalogDiff::Display::Text.adjust_for_display_datatype_changes(diff, true)
          end

          it 'should return an array of the correct size' do
            expect(diff.size).to eq(11)
          end

          # These are tests for each transformation. The order is important to this test, but it's
          # preserved by adjust_for_display_datatype_changes.
          it 'should handle <nil> and <empty string>' do
            expect(diff[0][2]).to eq('undef')
            expect(diff[0][3]).to eq('""')
          end

          it 'should handle <integer> and <string>' do
            expect(diff[1][2]).to eq(42)
            expect(diff[1][3]).to eq('"42"')
          end

          it 'should handle <empty string> and <nil>' do
            expect(diff[2][2]).to eq('""')
            expect(diff[2][3]).to eq('undef')
          end

          it 'should handle <string> and <integer>' do
            expect(diff[3][2]).to eq('"42"')
            expect(diff[3][3]).to eq(42)
          end

          it 'should handle <true> and "true"' do
            expect(diff[4][2]).to eq(true)
            expect(diff[4][3]).to eq('"true"')
          end

          it 'should handle "true" and <true>' do
            expect(diff[5][2]).to eq('"true"')
            expect(diff[5][3]).to eq(true)
          end

          it 'should handle <false> and "false"' do
            expect(diff[6][2]).to eq(false)
            expect(diff[6][3]).to eq('"false"')
          end

          it 'should handle "false" and <false>' do
            expect(diff[7][2]).to eq('"false"')
            expect(diff[7][3]).to eq(false)
          end

          it 'should pass back different integers' do
            expect(diff[8][2]).to eq(12_345)
            expect(diff[8][3]).to eq(67_890)
          end

          it 'should pass back nil versus a value' do
            expect(diff[9][2]).to eq(nil)
            expect(diff[9][3]).to eq(67_890)
          end

          it 'should pass back a value versus nil' do
            expect(diff[10][2]).to eq(12_345)
            expect(diff[10][3]).to eq(nil)
          end
        end
      end

      context 'change a parameter and add/remove another' do
        let(:diff) { JSON.parse(File.read(OctocatalogDiff::Spec.fixture_path('diffs/changed-and-added.json'))) }
        let(:result) { OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: false) }

        it 'should have the correct length' do
          expect(result.size).to eq(16), result.join("\n")
        end

        it 'should display the changed and added parameter' do
          pending 'Wrong result size' unless result.size == 16
          answer = [
            '  File[/usr/bin/node-waf] =>',
            '   parameters =>',
            '     ensure =>',
            '      - /usr/share/nvm/0.8.11/bin/node-waf',
            '      + link',
            '     target =>',
            '      + /usr/share/nvm/0.8.11/bin/node-waf',
            @separator
          ]
          addition = result[0..7]
          expect(addition).to eq(answer)
        end

        it 'should display the changed and removed parameter' do
          pending 'Wrong result size' unless result.size == 16
          answer = [
            '  File[/usr/bin/npm] =>',
            '   parameters =>',
            '     ensure =>',
            '      - link',
            '      + /usr/share/nvm/0.8.11/bin/npm',
            '     target =>',
            '      - /usr/share/nvm/0.8.11/bin/npm',
            @separator
          ]
          removal = result[8..15]
          expect(removal).to eq(answer)
        end
      end

      context 'parameter changes both changed and nested' do
        let(:diff) { JSON.parse(File.read(OctocatalogDiff::Spec.fixture_path('diffs/mountpoint.json'))) }
        let(:result) { OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, color: false, display_datatype_changes: true) }

        it 'should have the correct display' do
          answer = [
            '  Mount[/mnt/foo] =>',
            '   parameters =>',
            '     dump =>',
            '      + 0',
            '     ensure =>',
            '      - present',
            '      + mounted',
            '     pass =>',
            '      - "0"',
            '      + 0',
            @separator
          ]
          expect(result).to eq(answer)
        end
      end
    end

    #
    # Utility methods
    #

    context 'Utility methods' do
      before(:each) do
        String.colors_enabled = true
        Diffy::Diff.default_format = :color
      end

      describe '#diff_at_depth' do
        it 'should only print - if new object is nil' do
          result = OctocatalogDiff::CatalogDiff::Display::Text.diff_at_depth(0, 'text', nil)
          expect(result.size).to eq(1)
          expect(result.first).to eq("\e[0;31;49m  - text\e[0m")
        end

        it 'should only print + if old object is nil' do
          result = OctocatalogDiff::CatalogDiff::Display::Text.diff_at_depth(0, nil, 'text')
          expect(result.size).to eq(1)
          expect(result.first).to eq("\e[0;32;49m  + text\e[0m")
        end

        it 'should print - before + if there is a difference' do
          result = OctocatalogDiff::CatalogDiff::Display::Text.diff_at_depth(0, 'old', 'new')
          expect(result.size).to eq(2)
          expect(result[0]).to eq("\e[0;31;49m  - old\e[0m")
          expect(result[1]).to eq("\e[0;32;49m  + new\e[0m")
        end

        it 'should serialize non-strings' do
          result = OctocatalogDiff::CatalogDiff::Display::Text.diff_at_depth(0, { 'old' => true }, 'new' => [1, 2, 3])
          expect(result.size).to eq(2)
          expect(result[0]).to eq("\e[0;31;49m  - {\"old\"=>true}\e[0m")
          expect(result[1]).to eq("\e[0;32;49m  + {\"new\"=>[1, 2, 3]}\e[0m")
        end

        it 'should indent properly at depth=1' do
          result = OctocatalogDiff::CatalogDiff::Display::Text.diff_at_depth(1, 'text', 'bar')
          expect(result.first).to eq("\e[0;31;49m    - text\e[0m")
        end

        it 'should indent properly at depth=2' do
          result = OctocatalogDiff::CatalogDiff::Display::Text.diff_at_depth(2, 'text', 'bar')
          expect(result.first).to eq("\e[0;31;49m      - text\e[0m")
        end
      end

      describe '#diff_two_hashes_with_diffy' do
        it 'should display diff of two hashes containing arrays' do
          hash1 = { 'e' => [3, 4, 5, 6] }
          hash2 = { 'e' => [3, 4, 6, 7] }
          result = OctocatalogDiff::CatalogDiff::Display::Text.diff_two_hashes_with_diffy(depth: 1, hash1: hash1, hash2: hash2)
          answer = "    \e[31m-    5,\e[0m\n    \e[31m-    6\e[0m\n    \e[32m+    6,\e[0m\n    \e[32m+    7\e[0m"
          expect(result.join("\n")).to eq(answer)
        end

        it 'should display diff of two hashes containing strings' do
          hash1 = { 'e' => 'echo', 'f' => 'foxtrot', 'h' => 'hotel' }
          hash2 = { 'e' => 'echo', 'g' => 'golf', 'h' => 'hotel' }
          result = OctocatalogDiff::CatalogDiff::Display::Text.diff_two_hashes_with_diffy(depth: 1, hash1: hash1, hash2: hash2)
          answer = "    \e[31m-  \"f\": \"foxtrot\",\e[0m\n    \e[32m+  \"g\": \"golf\",\e[0m"
          expect(result.join("\n")).to eq(answer)
        end
      end

      describe '#simple_deep_merge' do
        it 'should merge one layer of hashes' do
          hash1 = { apple: 'red', lemon: 'yellow' }
          hash2 = { apple: 'green', orange: 'orange' }
          OctocatalogDiff::CatalogDiff::Display::Text.simple_deep_merge!(hash1, hash2)
          expect(hash1).to eq(apple: 'green', lemon: 'yellow', orange: 'orange')
          expect(hash2).to eq(apple: 'green', orange: 'orange')
        end

        it 'should merge a nested layer of hashes' do
          hash1 = { x: 'x', y: { a: 'a', b: 'bee', c: 'c' } }
          hash2 = { y: { b: 'b', d: 'd' }, z: 'z' }
          OctocatalogDiff::CatalogDiff::Display::Text.simple_deep_merge!(hash1, hash2)
          expect(hash1).to eq(x: 'x', y: { a: 'a', b: 'b', c: 'c', d: 'd' }, z: 'z')
          expect(hash2).to eq(y: { b: 'b', d: 'd' }, z: 'z')
        end

        it 'should overwrite a non-hash with a hash' do
          hash1 = { foo: 'foo' }
          hash2 = { foo: { bar: 'bar', baz: 'baz' } }
          OctocatalogDiff::CatalogDiff::Display::Text.simple_deep_merge!(hash1, hash2)
          expect(hash1).to eq(foo: { bar: 'bar', baz: 'baz' })
          expect(hash2).to eq(foo: { bar: 'bar', baz: 'baz' })
        end

        it 'should not de-duplicate or merge arrays' do
          hash1 = { x: { arr: [1, 2, 3, 4], y: 'y' } }
          hash2 = { x: { a: %w(a b c), arr: [1, 1, 2, 3, 5, 8] } }
          OctocatalogDiff::CatalogDiff::Display::Text.simple_deep_merge!(hash1, hash2)
          expect(hash1).to eq(x: { a: %w(a b c), arr: [1, 1, 2, 3, 5, 8], y: 'y' })
          expect(hash2).to eq(x: { a: %w(a b c), arr: [1, 1, 2, 3, 5, 8] })
        end

        it 'should raise an error if provided non-hashes' do
          expect { OctocatalogDiff::CatalogDiff::Display::Text.simple_deep_merge!(1, 2) }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe '#stringify_for_diffy' do
    it 'should return "" for empty string' do
      result = OctocatalogDiff::CatalogDiff::Display::Text.stringify_for_diffy('')
      expect(result).to eq('""')
    end

    it 'should return the object directly if it is a non-empty string' do
      result = OctocatalogDiff::CatalogDiff::Display::Text.stringify_for_diffy('hello')
      expect(result).to eq('hello')
    end

    it 'should return the object directly if it is an integer' do
      result = OctocatalogDiff::CatalogDiff::Display::Text.stringify_for_diffy(42)
      expect(result).to eq(42)
    end

    it 'should return the object directly if it is a float' do
      result = OctocatalogDiff::CatalogDiff::Display::Text.stringify_for_diffy(3.14159)
      expect(result).to eq(3.14159)
    end

    it 'should return the object class and inspected object for anything else' do
      result = OctocatalogDiff::CatalogDiff::Display::Text.stringify_for_diffy(:foobar)
      expect(result).to eq('Symbol: :foobar')
    end
  end

  describe '#_adjust_for_display_datatype' do
    it 'should leave objects untouched if they are not string-equal' do
      obj1 = 'foo'
      obj2 = :bar
      option = true
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      obj1_new, obj2_new = OctocatalogDiff::CatalogDiff::Display::Text._adjust_for_display_datatype(obj1, obj2, option, logger)
      expect(obj1_new).to eq(obj1)
      expect(obj2_new).to eq(obj2)
      expect(logger_str.string).to eq('')
    end

    it 'should nil both objects if they are string-equal and suppressed' do
      obj1 = 'foo'
      obj2 = :foo
      option = false
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      obj1_new, obj2_new = OctocatalogDiff::CatalogDiff::Display::Text._adjust_for_display_datatype(obj1, obj2, option, logger)
      expect(obj1_new).to eq(nil)
      expect(obj2_new).to eq(nil)
      expect(logger_str.string).to eq('')
    end

    it 'should nil both objects if they are both nil' do
      obj1 = nil
      obj2 = nil
      option = true
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      obj1_new, obj2_new = OctocatalogDiff::CatalogDiff::Display::Text._adjust_for_display_datatype(obj1, obj2, option, logger)
      expect(obj1_new).to eq(nil)
      expect(obj2_new).to eq(nil)
      expect(logger_str.string).to eq('')
    end

    it 'should return string undef vs ""' do
      obj1 = nil
      obj2 = ''
      option = true
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      obj1_new, obj2_new = OctocatalogDiff::CatalogDiff::Display::Text._adjust_for_display_datatype(obj1, obj2, option, logger)
      expect(obj1_new).to eq('undef')
      expect(obj2_new).to eq('""')
      expect(logger_str.string).to eq('')
    end

    it 'should return string "" vs undef' do
      obj1 = ''
      obj2 = nil
      option = true
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      obj1_new, obj2_new = OctocatalogDiff::CatalogDiff::Display::Text._adjust_for_display_datatype(obj1, obj2, option, logger)
      expect(obj1_new).to eq('""')
      expect(obj2_new).to eq('undef')
      expect(logger_str.string).to eq('')
    end

    it 'should return fixnum vs. quoted number' do
      obj1 = 42
      obj2 = '42'
      option = true
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      obj1_new, obj2_new = OctocatalogDiff::CatalogDiff::Display::Text._adjust_for_display_datatype(obj1, obj2, option, logger)
      expect(obj1_new).to eq(42)
      expect(obj2_new).to eq('"42"')
      expect(logger_str.string).to eq('')
    end

    it 'should return quoted number vs. fixnum' do
      obj1 = '42'
      obj2 = 42
      option = true
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      obj1_new, obj2_new = OctocatalogDiff::CatalogDiff::Display::Text._adjust_for_display_datatype(obj1, obj2, option, logger)
      expect(obj1_new).to eq('"42"')
      expect(obj2_new).to eq(42)
      expect(logger_str.string).to eq('')
    end

    it 'should handle quoted booleans' do
      obj1 = true
      obj2 = 'true'
      option = true
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      obj1_new, obj2_new = OctocatalogDiff::CatalogDiff::Display::Text._adjust_for_display_datatype(obj1, obj2, option, logger)
      expect(obj1_new).to eq(true)
      expect(obj2_new).to eq('"true"')
      expect(logger_str.string).to eq('')
    end

    it 'should handle quoted booleans' do
      obj1 = 'true'
      obj2 = true
      option = true
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      obj1_new, obj2_new = OctocatalogDiff::CatalogDiff::Display::Text._adjust_for_display_datatype(obj1, obj2, option, logger)
      expect(obj1_new).to eq('"true"')
      expect(obj2_new).to eq(true)
      expect(logger_str.string).to eq('')
    end

    it 'should handle quoted booleans' do
      obj1 = 'false'
      obj2 = false
      option = true
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      obj1_new, obj2_new = OctocatalogDiff::CatalogDiff::Display::Text._adjust_for_display_datatype(obj1, obj2, option, logger)
      expect(obj1_new).to eq('"false"')
      expect(obj2_new).to eq(false)
      expect(logger_str.string).to eq('')
    end
  end

  describe '#adjust_position_of_plus_minus' do
    it 'should work with colorized string' do
      input = "\e[31m-file line\e[0m"
      result = described_class.adjust_position_of_plus_minus(input)
      expect(result).to eq("\e[31m- file line\e[0m")
    end

    it 'should work with non-colorized string' do
      input = '-file line'
      result = described_class.adjust_position_of_plus_minus(input)
      expect(result).to eq('- file line')
    end
  end

  describe '#make_trailing_whitespace_visible' do
    it 'should work with colorized string' do
      input = "\e[31m- file line    \e[0m"
      result = described_class.make_trailing_whitespace_visible(input)
      expect(result).to eq("\e[31m- file line____\e[0m")
    end

    it 'should work with non-colorized string' do
      input = '- file line    '
      result = described_class.make_trailing_whitespace_visible(input)
      expect(result).to eq('- file line____')
    end

    it 'should work with colorized string with no trailing whitespace' do
      input = "\e[31m- file line\e[0m"
      result = described_class.make_trailing_whitespace_visible(input)
      expect(result).to eq("\e[31m- file line\e[0m")
    end

    it 'should work with a non-colorized string with no trailing whitespace' do
      input = '- file line'
      result = described_class.make_trailing_whitespace_visible(input)
      expect(result).to eq('- file line')
    end

    it 'should convert special spaces to character equivalents' do
      input = "test \r\n\t\f"
      result = described_class.make_trailing_whitespace_visible(input)
      expect(result).to eq('test_\\r\\n\\t\\f')
    end
  end

  describe '#add_trailing_newlines' do
    it 'should add newlines when neither string ends in newline' do
      result = described_class.add_trailing_newlines('one', 'two')
      expect(result).to eq(%W(one\n two\n))
    end

    it 'should not add newlines when one string ends in newline and the other does not' do
      result = described_class.add_trailing_newlines('one', "two\n")
      expect(result).to eq(%W(one two\n))
    end

    it 'should not add newlines when both strings end in newline' do
      result = described_class.add_trailing_newlines("one\n", "two\n")
      expect(result).to eq(%W(one\n two\n))
    end
  end
end

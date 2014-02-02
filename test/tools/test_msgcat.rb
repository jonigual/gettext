# Copyright (C) 2014  Kouhei Sutou <kou@clear-code.com>
#
# License: Ruby's or LGPL
#
# This library is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require "tempfile"
require "gettext/tools/msgcat"

class TestToolsMsgCat < Test::Unit::TestCase
  private
  def run_msgcat(input_pos, *options)
    inputs = input_pos.collect do |po|
      input = Tempfile.new("msgcat-input")
      input.write(po)
      input.close
      input
    end
    output = Tempfile.new("msgcat-output")
    command_line = ["--output", output.path]
    command_line.concat(options)
    command_line.concat(inputs.collect(&:path))
    GetText::Tools::MsgCat.run(*command_line)
    output.read
  end

  class TestHeader < self
    def setup
      @po1 = <<-PO
msgid ""
msgstr ""
"Project-Id-Version: gettext 3.0.0\\n"
      PO
      @po2 = <<-PO
msgid ""
msgstr ""
"Language: ja\\n"
      PO
    end

    def test_default
      assert_equal(@po1, run_msgcat([@po1, @po2]))
    end
  end

  class TestNoDuplicated < self
    class TestTranslated < self
      def setup
        @po1 = <<-PO
msgid "Hello"
msgstr "Bonjour"
        PO

        @po2 = <<-PO
msgid "World"
msgstr "Monde"
        PO
      end

      def test_default
        assert_equal(<<-PO.chomp, run_msgcat([@po1, @po2]))
#{@po1}
#{@po2}
        PO
      end
    end
  end

  class TestDuplicated < self
    class TestTranslated < self
      class TestSame < self
        def setup
          @po = <<-PO
msgid "Hello"
msgstr "Bonjour"
          PO
        end

        def test_default
          assert_equal(@po, run_msgcat([@po, @po]))
        end
      end

      class TestDifferent < self
        def setup
          @po1 = <<-PO
msgid "Hello"
msgstr "Bonjour"
          PO

          @po2 = <<-PO
msgid "Hello"
msgstr "Salut"
          PO
        end

        def test_default
          assert_equal(@po1, run_msgcat([@po1, @po2]))
        end
      end
    end
  end

  class TestSort < self
    class TestByMsgid < self
      def setup
        @po_alice = <<-PO
msgid "Alice"
msgstr ""
        PO

        @po_bob = <<-PO
msgid "Bob"
msgstr ""
        PO

        @po_charlie = <<-PO
msgid "Charlie"
msgstr ""
        PO
      end

      def test_sort_by_msgid
        sorted_po = <<-PO.chomp
#{@po_alice}
#{@po_bob}
#{@po_charlie}
        PO
        assert_equal(sorted_po,
                     run_msgcat([@po_charlie, @po_bob, @po_alice],
                                "--sort-by-msgid"))
      end

      def test_sort_output
        sorted_po = <<-PO.chomp
#{@po_alice}
#{@po_bob}
#{@po_charlie}
        PO
        assert_equal(sorted_po,
                     run_msgcat([@po_charlie, @po_bob, @po_alice],
                                "--sort-output"))
      end

      def test_no_sort_output
        not_sorted_po = <<-PO.chomp
#{@po_charlie}
#{@po_bob}
#{@po_alice}
        PO
        assert_equal(not_sorted_po,
                     run_msgcat([@po_charlie, @po_bob, @po_alice],
                                "--no-sort-output"))
      end
    end

    class TestByReference < self
      def setup
        @po_a1 = <<-PO
#: a.rb:1
msgid "Hello 3"
msgstr ""
        PO

        @po_a2 = <<-PO
#: a.rb:2
msgid "Hello 2"
msgstr ""
        PO

        @po_b1 = <<-PO
#: b.rb:1
msgid "Hello 1"
msgstr ""
        PO
      end

      def test_sort_by_location
        sorted_po = <<-PO.chomp
#{@po_a1}
#{@po_a2}
#{@po_b1}
        PO
        assert_equal(sorted_po,
                     run_msgcat([@po_b1, @po_a2, @po_a1],
                                "--sort-by-location"))
      end

      def test_sort_by_file
        sorted_po = <<-PO.chomp
#{@po_a1}
#{@po_a2}
#{@po_b1}
        PO
        assert_equal(sorted_po,
                     run_msgcat([@po_b1, @po_a2, @po_a1],
                                "--sort-by-file"))
      end
    end
  end

  class TestComment < self
    class TestReference < self
      def setup
        @po = <<-PO
# translator comment
#: a.rb:1
msgid "Hello"
msgstr ""
        PO
      end

      def test_no_location
        assert_equal(<<-PO, run_msgcat([@po], "--no-location"))
# translator comment
msgid "Hello"
msgstr ""
        PO
      end
    end

    class TestAll < self
      def setup
        @po = <<-PO
# translator comment
#. extracted comment
#: hello.rb:1
#, c-format
#| msgid "Hello"
msgid "Hello"
msgstr ""
        PO
      end

      def test_no_all_comments
        assert_equal(<<-PO, run_msgcat([@po], "--no-all-comments"))
msgid "Hello"
msgstr ""
        PO
      end
    end
  end

  class TestWidth < self
    def setup
      @po = <<-PO
msgid "long long long long long long long long long long long long long long long line"
msgstr ""
      PO
    end

    def test_default
      assert_equal(<<-PO, run_msgcat([@po]))
msgid ""
"long long long long long long long long long long long long long long long lin"
"e"
msgstr ""
      PO
    end

    def test_width
      assert_equal(<<-PO, run_msgcat([@po], "--width=40"))
msgid ""
"long long long long long long long long "
"long long long long long long long line"
msgstr ""
      PO
    end


    def test_wrap
      assert_equal(<<-PO, run_msgcat([@po], "--wrap"))
msgid ""
"long long long long long long long long long long long long long long long lin"
"e"
msgstr ""
      PO
    end

    def test_no_wrap
      assert_equal(<<-PO, run_msgcat([@po], "--no-wrap"))
msgid "long long long long long long long long long long long long long long long line"
msgstr ""
      PO
    end
  end
end

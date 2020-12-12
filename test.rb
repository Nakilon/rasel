require "minitest/autorun"
require "minitest/around/spec"
require "timeout"

require_relative "lib/rasel"

# TODO: assert that all RASEL() return with 0 exit code unless the opposite is expected

describe "tests" do
  around{ |test| Timeout.timeout(1){ test.call } }
  def assert_stack expectation, *args
    result = RASEL *args
    assert_equal expectation, [*result.stack.map(&:to_i), result.exitcode]
  end

  describe "executable" do
    it "hello world" do
      require "open3"
      require "tempfile"
      begin
        file = Tempfile.new "temp.rasel"
        file.write 'A"!dlroW ,olleH">:#,_@'
        file.flush
        string, status = Open3.capture2e "bin/rasel #{file.path}"
      ensure
        file.close
        file.unlink
      end
      assert_equal [0, "Hello, World!\n"], [status.exitstatus, string]
    end
  end

  describe "non-instructional" do
    it "trim spaces and empty lines" do
      assert_stack [64, 32, 118],
        " v @\n" +
        "\n" +
        " > v\n" +
        "   \"\n" +
        "\n \n\n"
    end
    it "print to STDOUT" do
      # TODO: mock
      begin
        STDOUT, stdout = StringIO.new, STDOUT
        RASEL ",@", STDOUT
      ensure
        STDOUT, stdout = stdout, STDOUT
      end
      assert_equal ?\0.b, stdout.string
    end
    it "print to StringIO" do
      string = StringIO.new
      RASEL ",@", string
      assert_equal ?\0.b, string.string
    end
  end

  describe "instructional" do

    describe "old" do
      it '"' do assert_stack ["@".ord],  '"@' end
      it '#"' do assert_stack      [0], '#"@' end
      it "0..9, A..Z" do assert_stack [*0..35], "#{[*0..9].join}#{[*?A..?Z].join}@" end
      describe "(rely on 0..9, A..Z)" do

        it "$" do assert_stack          [1],       "$12$@" end
        it ":" do assert_stack [0, 0, 1, 1],        ":1:@" end
        it ?\\ do assert_stack    [0, 1, 0],      "\\1\\@" end
        it "!" do assert_stack [1, 1, 0, 0],    "!0!1!2!@" end
        it "!-" do assert_stack      [0, 0],    "1-!02-!@" end
        it "/" do assert_stack [0, 0, 1, 2], "//12/22/21/@" end
        it "-" do assert_stack [-90000, 0], "--"+"9-"*10000+"0@" end
        it "/-" do assert_equal [-(1r/2)], RASEL("1-2/0@").stack end
        it "><^v" do
          assert_stack [1, 2, 3, 4],
            <<~HEREDOC
              <@^1
              3v>
              5425
            HEREDOC
        end
        [
          [[1, 3], "   00"],
          [[2, 4], "   11"],
          [[2, 3], "   01"],
          [[1, 4], "   10"],
          [[1, 3], "1-01-"],
        ].each do |expectation, code|
          it "|_- #{code}" do
            assert_stack expectation,
              <<~HEREDOC
                #{code}|
                   41_13@
                   42_23@
              HEREDOC
          end
        end
        it ".-" do assert_equal "0 10 255 0 ",        RASEL(".A."+"5-"*51+"-..@").stdout.string end
        it ",-" do assert_equal "\x00\x0A\xFF\x00".b, RASEL(",A,"+"5-"*51+"-,,@").stdout.string end
        it "~" do
          assert_stack [2], "~1@2", StringIO.new, StringIO.new
          assert_stack [0, 10, 255, 0], "~~~~@", StringIO.new,
            StringIO.new.tap{ |s| [0, 10, 255, 0].reverse_each &s.method(:ungetbyte) }
        end
        it "&" do
          assert_stack [2], "&1@2", StringIO.new, StringIO.new
          [?\0, ?\xa, ?\xff].each do |c|
            assert_stack [12, 34], "&&@", StringIO.new,
              StringIO.new.tap{ |s| "#{c}-12#{c}-34#{c}".bytes.reverse_each &s.method(:ungetbyte) }
          end
        end
      end
    end

    describe "changed" do
      it "@" do
        assert_equal 0, RASEL("@").exitcode
        assert_equal 2, RASEL("2@").exitcode
        assert_equal 255, RASEL("2-@").exitcode
        assert_equal 255, RASEL("12/@").exitcode
      end
    end

    describe "new" do
      before do assert_equal 0, RASEL(?@).exitcode end

      it "j"  do assert_stack [5, 6], "2j3456@" end
      it "j-" do assert_stack [2, 3], "6-j123@" end
    end

  end

end

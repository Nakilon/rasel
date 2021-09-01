require "minitest/autorun"
require "minitest/around/spec"
require "timeout"

require_relative "lib/rasel"

# TODO: assert that all RASEL() return with 0 exit code unless the opposite is expected

describe "bin" do

  describe "rasel" do
    around{ |test| Timeout.timeout(RUBY_PLATFORM == "java" ? 4 : 1){ test.call } }
    require "open3"
    [
      ["cat.rasel < examples/cat.rasel", 0, File.read("examples/cat.rasel")],
      ["helloworld.rasel", 0, "Hello, World!\n"],
      ["naive_if_zero.rasel", 0, "false\nfalse\ntrue\nfalse\nfalse\n"],
      ["short_if_zero.rasel", 0, "false\nfalse\ntrue\nfalse\nfalse\n"],
      ["factorial.rasel", 0, "120 ", "echo 5 | "],
      ["fibonacci.rasel", 89, "55 ", "echo 10 | "],
      ["project_euler/1.rasel", 0, "233168 ", "echo 1000 | "],
    ].each do |cmd, expected_status, expected_stdout, prefix|
      it cmd do
        string, status = Open3.capture2e "#{prefix}./bin/rasel examples/#{cmd}"
        assert_equal [expected_status, expected_stdout], [status.exitstatus, string]
      end
    end
  end

  describe "rasel" do
    around{ |test| Timeout.timeout(1){ test.call } }
    it "rasel-annotated" do
      # can't implemented this test using Open3 because of a weird Ruby bug: Illegal seek @ rb_io_tell
      stdout = Tempfile.new "rasel-test-stdout"
      stderr = Tempfile.new "rasel-test-stderr"
      begin
        system "echo 12 | ./bin/rasel-annotated examples/cat.rasela 1>#{stdout.path} 2>#{stderr.path}"
        assert_equal [0, <<~HEREDOC, ""], [$?.exitstatus, stdout.read, stderr.read]
          ["loop",[]]
          ["loop",[[49,"..)"]]]
          ["print","1"]
          ["loop",[]]
          ["loop",[[50,"..)"]]]
          ["print","2"]
          ["loop",[]]
          ["loop",[[10,"..)"]]]
          ["print","\\n"]
          ["loop",[]]
        HEREDOC
      ensure
        stdout.close
        stdout.unlink
        stderr.close
        stderr.unlink
      end
    end
  end

end

describe "lib" do
  around{ |test| Timeout.timeout(1){ test.call } }
  def assert_stack expectation, *args
    result = RASEL *args
    assert_equal expectation, [*result.stack, result.exitcode]
  end

  describe "non-instructional" do
    it "trim spaces and empty lines" do
      assert_stack [64, 32, 118],
        " v @\n" +
        "\n" +
        " > v\n" +
        "   \"\n" +
        "\n \n\n"
      assert_stack [1, 2],
        '  v@ '"\n"\
        '   2 '"\n"\
        '   @ '"\n"\
        '@v># '"\n"\
        ' >1v '"\n"\
        '   # '"\n"\
        '     '
    end
    it "exit status code 255 on invalid character" do
      assert_equal 255, RASEL("Ы").exitcode
    end
    it "print to STDOUT" do
      # TODO: mock
      begin
        STDOUT, stdout = StringIO.new, STDOUT
        RASEL ",@", STDOUT
      ensure
        STDOUT, stdout = stdout, STDOUT
      end
      assert_equal ?\0, stdout.string
    end
    it "print to StringIO" do
      string = StringIO.new
      RASEL ",@", string
      assert_equal ?\0, string.string
    end
  end

  describe "instructional" do

    describe "old" do
      it '"'  do assert_stack ["@".ord], '"@' end
      it '#' do assert_stack [1], '##1@' end
      it '#"Ы' do assert_stack [64, 208, 171, 35, 64], '#@"@Ы' end
      it '#><^vЫ' do
        assert_stack [1, 2, 3],
          <<~HEREDOC
            1v@
            v>2\#
            >3v
              \#
                Ы
          HEREDOC
      end
      it "0..9, A..Z" do assert_stack [*0..35], "#{[*0..9].join}#{[*?A..?Z].join}@" end
      it "$"  do assert_stack [1], "$12$@" end
      it ":" do assert_stack [0, 0, 1, 1], ":1:@" end
      it "><^v" do
        assert_stack [1, 2, 3, 4],
          <<~HEREDOC
            <@^1
            3v>
            5425
          HEREDOC
      end
      it "-" do assert_stack [-90000, 0], "--"+"9-"*10000+"0@" end
      it "/" do assert_stack [0, 0, 0.5, 1, 2], "//10/12/22/21/@" end
      it "%" do assert_stack [0, 0, 1, 0, 0], "%%10%12%22%21%@" end
      it "/-" do assert_equal [-0.5], RASEL("1-2/0@").stack end
      it "%-" do assert_equal [1], RASEL("1-2%0@").stack end
      it ".-" do assert_equal "0 10 255 0 ",        RASEL(".A."+"5-"*51+"-..@").stdout.string end
      it ",-" do assert_equal "\x00\x0A\xFF\x00".b, RASEL(",A,"+"5-"*51+"-,,@").stdout.string end
      it ".- negative float" do assert_equal "-0.3333333333333333 ", RASEL("13/-.@").stdout.string end
      it ",- errors" do
        assert_equal 255, RASEL("1-,@").exitcode
        assert_equal 255, RASEL("GG*,@").exitcode
        assert_equal 255, RASEL("12/,@").exitcode
      end
    end

    describe "changed" do
      it "@" do
        assert_equal 0, RASEL("@").exitcode
        assert_equal 2, RASEL("2@").exitcode
        assert_equal 255, RASEL("2-@").exitcode
        assert_equal 255, RASEL("12/@").exitcode
      end
      it "~" do
        assert_stack [1], "~1@2", StringIO.new, StringIO.new
        assert_stack [0, 10, 255, 0], "~0~0~0~0@", StringIO.new,
          StringIO.new.tap{ |s| [0, 10, 255, 0].reverse_each &s.method(:ungetbyte) }
      end
      it "&" do
        assert_stack [1], "&1@2", StringIO.new, StringIO.new
        [0, 10, 255].each do |c|
          assert_stack [12, 34, c, 56], "&0&0~0&0@", StringIO.new,
            StringIO.new.tap{ |s| "#{c.chr}-12#{c.chr}-34#{c.chr}-56".bytes.reverse_each &s.method(:ungetbyte) }
        end
      end
      [
        [[1], ""],
        [[0], "1"],
        [[1], "1-"],
        [[0], "12/"],
        [[1], "12/-"],
      ].each do |expectation, code|
        it "? #{code}" do
          assert_stack expectation, "#{code}?1@"
          assert_stack expectation, "v#{code}?1@".chars.zip.transpose.join(?\n)
          assert_stack expectation, "<@1?#{code.reverse}"
          assert_stack expectation, "^@1?#{code.reverse}".chars.zip.transpose.join(?\n)
        end
      end
      it "\\" do assert_stack [2, 0, 4, 0], "4321001-02-\\\\\\\\\\@" end
      it "exit status code 255 on non-integer \\ index" do
        assert_equal 0, RASEL("01/\\@").exitcode
        assert_equal 255, RASEL("12/\\@").exitcode
        assert_equal 255, RASEL("12/-\\@").exitcode
      end
    end

    describe "new" do
      # TODO: non-instructional-like tests about jumping over spaces on the edges
      it "j" do assert_stack [1], "j1@" end
      it 'j"' do assert_stack [5, 6], '3j2"456@' end
      it "j-" do assert_stack [2, 3], "6-j123@" end
      it "exit status code 255 on non-integer jump" do
        assert_equal 255, RASEL("12/j@").exitcode
      end
    end

  end

end

describe "other" do
  def assert_stack expectation, *args
    result = RASEL *args
    assert_equal expectation, [*result.stack, result.exitcode]
  end
  it "constants" do
    File.foreach("constants.txt").with_index do |line, i|
      next if line.chomp.empty?
      s = 256.times.map{ rand(35)+1 }
      assert_stack [*s,i+1,0], "#{s.map{|_|_.to_s(36).upcase}.join}G1G//j#{"@"*256}#{line.chomp}0@"
    end
  end
end

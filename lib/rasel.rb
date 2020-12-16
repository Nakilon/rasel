Encoding::default_internal = Encoding::default_external = "ASCII-8BIT"
END { RubyProf::FlatPrinter.new(RubyProf.stop).print STDERR, min_percent: 1 } if ENV["PROFILE"]

def RASEL source, stdout = StringIO.new, stdin = STDIN
  lines = source.tap{ |_| fail "empty source" if _.empty? }.gsub(/ +$/,"").split(?\n)
  code = lines.map{ |_| _.ljust(lines.map(&:size).max).bytes }
  stack = []
  pop = ->{ stack.pop || 0r }
  dx, dy = 1, 0
  x, y = -1, 0

  history = {}
  move = lambda do
    y = (y + dy) % code.size
    x = (x + dx) % code[y].size
    next unless ENV.key?("DEBUG_HISTORY") && code[y][x] == 32
    history[[x, y]] ||= 0
    history[[x, y]] += 1
  end
  time = Time.now
  thread = Thread.new do
    loop do
      unless Time.now < time + 1
        time += 1
        p history.sort_by(&:last).last(10)
      end
      sleep 0.1
    end
  end if ENV.key? "DEBUG_HISTORY"
  if ENV["PROFILE"]
    require "ruby-prof"
    RubyProf.start
  end

  reverse = ->{ dy, dx = -dy, -dx }
  stringmode = false
  error = Proc.new{ return Struct.new(:stdout, :stack, :exitcode).new stdout, stack, 255 }
  loop do
    move[]
    byte = code[y][x]
    char = byte.chr
    STDERR.puts [char, stringmode, (stack.last Integer ENV["DEBUG"] rescue stack)].inspect if ENV.key? "DEBUG"
    next stack.push byte if stringmode && char != ?"
    return Struct.new(:stdout, :stack, :exitcode).new stdout, stack, (
      t = pop[]
      1 != t.denominator || t < 0 || t > 255 ? 255 : t.to_i
    ) if char == ?@
    case char
      when ?\s

      when ?0..?9, ?A..?Z ; stack.push char.to_i(36).to_r
      when ?" ; stringmode ^= true
      when ?# ; move[]
      when ?$ ; pop[]
      when ?: ; stack.concat [pop[]] * 2
      when ?- ; stack.push -(pop[] - pop[])
      when ?\\ ; stack.concat [pop[], pop[]]
      when ?/ ; b, a = pop[], pop[]; stack.push (b.zero? ? 0 : a / b)
      when ?% ; b, a = pop[], pop[]; stack.push (b.zero? ? 0 : a % b)
      when ?v ; dx, dy =  0,  1
      when ?> ; dx, dy =  1,  0
      when ?^ ; dx, dy =  0, -1
      when ?< ; dx, dy = -1,  0
      when ?? ; move[] if pop[] > 0
      when ?a
        t = pop[]
        error[] if 0 > t || 1 != t.denominator
        stack.push t.zero? ? 0 : stack[-t] || 0
      when ?. ; stdout.print "#{_ = pop[]; 1 != _.denominator ? _.to_f : _.to_i} "
      when ?, ; stdout.print "#{_ = pop[]; 1 != _.denominator ? error[] : _ < 0 || _ > 255 ? error[] : _.to_i.chr}"
      when ?~ ; if c = stdin.getbyte then stack.push c else reverse[] end
      when ?&
        getc = ->{ stdin.getc or (reverse[]; throw nil) }
        catch nil do
          nil until (?0..?9).include? c = getc[]
          while (?0..?9).include? cc = getc[] ; c << cc end
          stdin.ungetbyte cc
          stack.push c.to_i
        end
      when ?j
        t = pop[]
        error[] if 1 != t.denominator
        if 0 < t
          y = (y + dy * t.to_i) % code.size
          x = (x + dx * t.to_i) % code[y].size
        else
          reverse[]
          y = (y - dy * t.to_i) % code.size
          x = (x - dx * t.to_i) % code[y].size
          reverse[]
        end

      else ; error[]
    end
  end
end

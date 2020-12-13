Encoding::default_internal = Encoding::default_external = "ASCII-8BIT"

def RASEL source, stdout = StringIO.new, stdin = STDIN
  lines = source.tap{ |_| fail "empty source" if _.empty? }.gsub(/ +$/,"").split(?\n)
  code = lines.map{ |_| _.ljust(lines.map(&:size).max).bytes }
  stack = []
  pop = ->{ stack.pop || 0r }
  dx, dy = 1, 0
  x, y = -1, 0
  move = lambda do
    y = (y + dy) % code.size
    x = (x + dx) % code[y].size
  end
  reverse = ->{ dy, dx = -dy, -dx }
  stringmode = false
  error = Proc.new{ return Struct.new(:stdout, :stack, :exitcode).new stdout, stack, 255 }

  loop do
    move[]
    char = code[y][x] || 32r
    STDERR.puts [char.chr, stringmode, stack].inspect if ENV["DEBUG"]
    next stack.push char if stringmode && char.chr != ?"
    return Struct.new(:stdout, :stack, :exitcode).new stdout, stack, (
      t = pop[]
      1 != t.denominator || t < 0 || t > 255 ? 255 : t.to_i
    ) if char.chr == ?@
    case char.chr
      when ?\s

      ### Befunge
      when ?" ; stringmode ^= true
      when ?# ; move[]
      when ?0..?9, ?A..?Z ; stack.push char.chr.to_i(36).to_r
      when ?$ ; pop[]
      when ?: ; stack.concat [pop[]] * 2
      when ?\\ ; stack.concat [pop[], pop[]]
      when ?> ; dx, dy =  1,  0
      when ?< ; dx, dy = -1,  0
      when ?^ ; dx, dy =  0, -1
      when ?v ; dx, dy =  0,  1
      when ?- ; stack.push -(pop[] - pop[])
      when ?/ ; b, a = pop[], pop[]; stack.push (b.zero? ? 0 : a / b)
      when ?% ; b, a = pop[], pop[]; stack.push (b.zero? ? 0 : a % b)
      when ?? ; reverse[] if pop[] <= 0
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
          t.to_i.times{ move[] }
        else
          reverse[]
          (-t).to_i.times{ move[] }
          reverse[]
        end
      when ?a
        t = pop[]
        error[] if 0 > t || 1 != t.denominator
        stack.push t.zero? ? 0 : stack[-t] || 0

      else ; error[]
    end
  end
end

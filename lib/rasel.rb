Encoding::default_internal = Encoding::default_external = "ASCII-8BIT"

def RASEL source, stdout = StringIO.new, stdin = STDIN
  code = source.tap{ |_| fail "empty source" if _.empty? }.split(?\n).map(&:bytes)
  stack = []
  pop = ->{ stack.pop || 0r }
  dx, dy = 1, 0
  go_west  = ->{ dx, dy = -1,  0 }
  go_east  = ->{ dx, dy =  1,  0 }
  go_north = ->{ dx, dy =  0, -1 }
  go_south = ->{ dx, dy =  0,  1 }
  x, y = -1, 0
  move = lambda do
    y = (y + dy) % code.size
    x = (x + dx) % code[y].size
  end
  reverse ->{ dy, dx = -dy, -dx }
  stringmode = false

  loop do
    move[]
    char = code[y][x] || 32
    STDERR.puts [char.chr, stack].inspect if ENV["DEBUG"]
    return Struct.new(:stdout, :stack, :exitcode).new stdout, stack, pop[] if char.chr == ?@
    next stack << char if stringmode && char.chr != ?"
    next unless (33..126).include? char   # just for performance
    case char.chr

      ### Befunge
      when ?" ; stringmode ^= true
      when ?0..?9, ?A..?Z ; stack << char.to_i(36)
      when ?$ ; pop[]
      when ?: ; stack.concat [pop[]] * 2
      when ?\\ ; stack.concat [pop[], pop[]]
      when ?# ; move[]
      when ?> ; go_east[]
      when ?< ; go_west[]
      when ?^ ; go_north[]
      when ?v ; go_south[]
      when ?- ; stack.push -(pop[] - pop[])
      when ?/ ; b, a = pop[], pop[]; stack.push (b.zero? ? 0 : a / b)
      when ?% ; b, a = pop[], pop[]; stack.push (b.zero? ? 0 : a % b)
      when ?| ; pop[] > 0 ? go_south[] : go_north[]
      when ?_ ; pop[] > 0 ? go_east[] : go_west[]
      when ?! ; stack.push (pop[].zero? ? 1r : 0r)
      when ?, ; stdout.print pop[].chr
      when ?. ; stdout.print "#{pop[]} "
      when ?~ ; if c = stdin.getbyte then stack.push c else reverse[] end
      when ?&
        getc = ->{ stdin.getc or (reverse[]; throw nil) }
        catch nil do
          nil until (?0..?9).include? c = getc[]
          while (?0..?9).include? cc = getc[] ; c << cc end
          stack.push c.to_i
        end
      when ?j
        if 0 < t = pop[]
          t.times{ move[] }
        else
          reverse[]
          (-t).times{ move[] }
          reverse[]
        end

      ### RASEL

    end
  end
end

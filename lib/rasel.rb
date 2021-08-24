Encoding::default_internal = Encoding::default_external = "ASCII-8BIT"
END { RubyProf::FlatPrinter.new(RubyProf.stop).print STDERR, min_percent: 1 } if ENV["PROFILE"]

require "delegate"
class RASELStackItem < DelegateClass Rational
  attr_reader :annotation
  def initialize n, annotation
    super n
    @annotation = annotation
  end
end

RASELResultStruct = Struct.new :stdout, :stack, :exitcode
def RASEL source, stdout = StringIO.new, stdin = STDIN
  stack = []
  pop = ->{ stack.pop || 0 }
  error = Proc.new{ return RASELResultStruct.new stdout, stack, 255 }

  case source
  when String
    lines = source.tap{ |_| raise ArgumentError.new "empty source" if _.empty? }.gsub(/ +$/,"").split(?\n)
    code = lines.map{ |_| _.ljust(lines.map(&:size).max).bytes }
  when Array
    annotate = true
    code = Array.new(source.map{|y,|y}.max+1){ Array.new(source.map{|_,x,|x}.max+1){ " ".ord } }
    source.each{ |y, x, c, a| code[y][x] = [c.ord, a] }
    stdout.instance_eval do
      pos = self.pos
      old_puts = method :puts
      prev = nil
      define_singleton_method :puts do |str, reason|
        next if prev == dump = JSON.dump([reason, str])
        old_puts.call prev = dump
        if 10_000_000 < stdout.pos - pos
          old_puts.call JSON.dump [:exit, "printed size"]
          error.call
        end
      end
      define_singleton_method :print do |str|
        puts str, :print
      end
    end
  else
    raise ArgumentError.new "unsupported source class: #{source.class}"
  end
  dx, dy = 1, 0
  x, y = -1, 0

  # debugging and profiling
  history = {}
  debug_history = ENV.key? "DEBUG_HISTORY"
  move = lambda do
    y = (y + dy) % code.size
    x = (x + dx) % code[y].size
    next unless debug_history && (code[y][x] == 32 || code[y][x][0] == 32)
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
  end if debug_history
  if ENV["PROFILE"]
    require "ruby-prof"
    RubyProf.start
  end

  reverse = ->{ dy, dx = -dy, -dx }
  stringmode = false
  debug = ENV.key? "DEBUG"
  loop do
    if 1 < Time.now - time
      stdout.puts "time", :exit
      error.call
    end
    stdout.puts stack.map{ |_| _.respond_to?(:annotation) && _.annotation ? [_, _.annotation] : _ }, :loop if annotate

    move[]
    byte, annotation = code[y][x]
    char = byte.chr
    STDERR.puts [char, stringmode, (stack.last Integer ENV["DEBUG"] rescue stack)].inspect if debug

    next stack.push byte if stringmode && char != ?"
    return RASELResultStruct.new stdout, stack, (
      t = pop[]
      1 != t.denominator || t < 0 || t > 255 ? 255 : t.to_i
    ) if char == ?@
    case char
      when ?\s

      when ?0..?9 ; stack.push byte - 48
      when ?A..?Z ; stack.push byte - 55
      when ?" ; stringmode ^= true
      when ?# ; move[]
      when ?$ ; pop[]
      when ?: ; popped = pop[]; stack.push popped; stack.push RASELStackItem.new popped, annotation
      when ?- ; stack.push -(pop[] - pop[])
      when ?/ ; b, a = pop[], pop[]; stack.push RASELStackItem.new b.zero? ? 0 : Rational(a) / b, annotation
      when ?% ; b, a = pop[], pop[]; stack.push RASELStackItem.new b.zero? ? 0 : Rational(a) % b, annotation
      when ?v ; dx, dy =  0,  1
      when ?> ; dx, dy =  1,  0
      when ?^ ; dx, dy =  0, -1
      when ?< ; dx, dy = -1,  0
      when ?? ; move[] if pop[] > 0
      when ?\\
        t = pop[]
        error.call if 1 != t.denominator
        stack.unshift 0 until stack.size > t
        stack[-t-1], stack[-1] = stack[-1], stack[-t-1] unless 0 > t
      when ?. ; stdout.print "#{_ = pop[]; 1 != _.denominator ? _.to_f : _.to_i} "
      when ?, ; stdout.print "#{_ = pop[]; 1 != _.denominator ? error.call : _ < 0 || _ > 255 ? error.call : _.to_i.chr}"
      when ?~ ; if _ = stdin.getbyte then stack.push _; move[] end
      when ?&
        getc = ->{ stdin.getc or throw nil }
        catch nil do
          nil until (?0..?9).include? c = getc[]
          while (?0..?9).include? cc = stdin.getc ; c << cc end
          stdin.ungetbyte cc if cc
          stack.push c.to_i
          move[]
        end
      when ?j
        t = pop[]
        error.call if 1 != t.denominator
        y = (y + dy * t.to_i) % code.size
        x = (x + dx * t.to_i) % code[y].size

      else ; error.call
    end
  end
end

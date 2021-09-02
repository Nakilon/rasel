Encoding::default_internal = Encoding::default_external = "ASCII-8BIT"

module RASEL
  ResultStruct = Struct.new :stdout, :stack, :exitcode

  def self.run source, stdout = StringIO.new, stdin = STDIN
    stack = []
    pop = ->{ stack.pop || 0 }
    error = Proc.new{ return RASEL::ResultStruct.new stdout, stack, 255 }

    lines = source.tap{ |_| raise ArgumentError.new "empty source" if _.empty? }.gsub(/ +$/,"").split(?\n)
    code = lines.map{ |_| _.ljust(lines.map(&:size).max).bytes }

    dx, dy = 1, 0
    x, y = -1, 0

    # debugging and profiling (currently not maintained)
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

    reverse = ->{ dy, dx = -dy, -dx }
    stringmode = false
    debug = ENV.key? "DEBUG"
    loop do
      move[]
      byte = code[y][x]
      char = byte.chr
      STDERR.puts [char, stringmode, (stack.last Integer ENV["DEBUG"] rescue stack)].inspect if debug

      next stack.push byte if stringmode && char != ?"
      return RASEL::ResultStruct.new stdout, stack, (
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
        when ?: ; stack.concat [pop[]] * 2
        when ?- ; stack.push -(pop[] - pop[])
        when ?/ ; b, a = pop[], pop[]; stack.push b.zero? ? 0 : Rational(a) / b
        when ?% ; b, a = pop[], pop[]; stack.push b.zero? ? 0 : Rational(a) % b
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

  require "delegate"
  class StackItem < DelegateClass Rational
    attr_reader :annotation
    def initialize n, annotation
      super n
      @annotation = annotation || (n.annotation if n.respond_to? :annotation)
    end
  end
  def self.run_annotated source, stdout = StringIO.new, stdin = STDIN
    stack = []
    pop = ->{ stack.pop || 0 }
    error = Proc.new{ return ResultStruct.new stdout, stack, 255 }

    code = Array.new(source.map{|y,|y}.max+1){ Array.new(source.map{|_,x,|x}.max+1){ " ".ord } }
    source.each{ |y, x, c, a| code[y][x] = [c.ord, a] unless c.empty? }
    stdout.instance_eval do
      pos = self.pos
      old_puts = method :puts
      prev = nil
      define_singleton_method :puts do |str, reason|
        next if prev == dump = JSON.dump([reason, str])
        old_puts.call prev = dump
        if 500_000 < stdout.pos - pos
          old_puts.call JSON.dump [:abort, "printed size"]
          error.call
        end
      end
      define_singleton_method :print do |str|
        puts str, :print
      end
    end

    dx, dy = 1, 0
    x, y = -1, 0

    move = lambda do
      y = (y + dy) % code.size
      x = (x + dx) % code[y].size
    end
    time = Time.now

    reverse = ->{ dy, dx = -dy, -dx }
    stringmode = false
    loop do
      if 1 < Time.now - time
        stdout.puts "timeout", :abort
        error.call
      end
      stdout.puts stack.map{ |_| _.respond_to?(:annotation) && _.annotation ? [_, _.annotation] : _ }, :loop

      move[]
      byte, annotation = code[y][x]
      char = byte.chr

      next stack.push StackItem.new byte, annotation if stringmode && char != ?"
      return ResultStruct.new stdout, stack, (
        t = pop[]
        1 != t.denominator || t < 0 || t > 255 ? 255 : t.to_i
      ) if char == ?@
      case char
        when ?\s

        when ?0..?9 ; stack.push StackItem.new byte - 48, annotation
        when ?A..?Z ; stack.push StackItem.new byte - 55, annotation
        when ?" ; stringmode ^= true
        when ?# ; move[]
        when ?$ ; pop[]
        when ?: ; popped = pop[]; stack.push popped; stack.push StackItem.new popped, annotation
        when ?- ; stack.push StackItem.new -(pop[] - pop[]), annotation
        when ?/ ; b, a = pop[], pop[]; stack.push StackItem.new b.zero? ? 0 : Rational(a) / b, annotation
        when ?% ; b, a = pop[], pop[]; stack.push StackItem.new b.zero? ? 0 : Rational(a) % b, annotation
        when ?v ; dx, dy =  0,  1
        when ?> ; dx, dy =  1,  0
        when ?^ ; dx, dy =  0, -1
        when ?< ; dx, dy = -1,  0
        when ?? ; move[] if pop[] > 0
        when ?\\
          t = pop[]
          error.call if 1 != t.denominator
          stack.unshift 0 until stack.size > t
          stack[-t-1], stack[-1] = StackItem.new(stack[-1], annotation), stack[-t-1] unless 0 > t
        # TODO: annotate prints
        when ?. ; stdout.print "#{_ = pop[]; 1 != _.denominator ? _.to_f : _.to_i} "
        when ?, ; stdout.print "#{_ = pop[]; 1 != _.denominator ? error.call : _ < 0 || _ > 255 ? error.call : _.to_i.chr}"
        when ?~ ; if _ = stdin.getbyte then stack.push StackItem.new _, annotation; move[] end
        when ?&
          getc = ->{ stdin.getc or throw nil }
          catch nil do
            nil until (?0..?9).include? c = getc[]
            while (?0..?9).include? cc = stdin.getc ; c << cc end
            stdin.ungetbyte cc if cc
            stack.push StackItem.new c.to_i, annotation
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

  def self.write_pretty_json where, what
    File.write where, "[\n  " + (
      what.map(&JSON.method(:dump)).join ",\n  "
    ) + "\n]\n"
  end
end

def RASEL *args
  RASEL::run *args
end

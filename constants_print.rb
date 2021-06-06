require_relative "lib/rasel"

h = []
l = lambda do |p, s, t, &b|
  s.each do |a|
    c = "#{p}#{t % a}"
    r = RASEL "#{c}0@"
    fail unless r.exitcode.zero?
    result = r.stack.last
    unless 0 > result || result.denominator != 1
      h[result] = h[result] || []
      h[result].push c
    end
    b.call c if b
  end
end

a = ([*32..126]-[34]).map(&:chr)
l.call("", a, "\"%s\"")
l.call("", a.product(a, a).map(&:join), "\"%s\"//")
a = [*?0..?9, *?A..?Z]
l.call("", a, "%s") do |b|
  l.call(b, a, "1%s//") do |b|
    l.call(b, a, "%s-")
  end
end

h.each_with_index{ |e, i| puts(("#{e.sort_by{ |_| [_.size, _.delete("^0-9A-Za-z").chars.max || "0", _.reverse] }.take(1).join "\t"}" if e)) }

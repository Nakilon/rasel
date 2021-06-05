require "rasel"

h = []
l = lambda do |p, s, t, &b|
  s.each do |a|
    c = "#{p}#{t % a}"
    r = RASEL "#{c}0@"
    fail unless r.exitcode.zero?
    unless 0 > result = r.stack.last
      h[result] = h[result] || []
      h[result].push c
    end
    b.call c if b
  end
end

l.call("", ([*32..126]-[34]).map(&:chr), "\"%s\"")
a = [*?0..?9, *?A..?Z]
l.call("", a, "%s") do |b|
  l.call(b, a, "1%s//") do |b|
    l.call(b, a, "%s-")
  end
end

h.each_with_index{ |e, i| puts(("#{e.sort_by{ |_| [_.size, _.delete("^0-9A-Z").chars.max || "0", _.reverse] }.take(1).join "\t"}" if e)) }

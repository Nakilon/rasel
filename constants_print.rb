require "rasel"
h = []
a = [*?0..?9, *?A..?Z]
a.product(a) do |i, j|
  c = "#{i}1#{j}//"
  code = "#{c}0@"
  result = RASEL(code).stack.last
  h[result] = h[result] || []
  h[result].push c
end
h.each_with_index{ |e, i| puts(("#{e.sort_by{ |_| [_.delete("^0-9A-Z").chars.max || "0", _.reverse] }.join " "}" if e)) }

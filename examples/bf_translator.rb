x = y = 0
code = [[]]
stack = []
append = ->str{ str.chars{ |c| code[y][x] = c; x += 1 } }
e = $<.read.delete("^-+<>[].,").each_char
optim = lambda do |c|
  n = 1
  (e.next; n += 1) while c == (e.peek rescue StopIteration)
  a, b = n.divmod(35)
  [*([?G]*a), b].map{ |d| "#{d.to_s 36}-".upcase }.join
end
loop do
  case e.next
  when ?-
    append.call ":03--::\\"
    append.call "#{optim.call ?-}G1G//%"
    append.call "1\\1-\\$"
  when ?+
    append.call ":03--::\\"
    append.call "0#{optim.call ?+}-G1G//%"
    append.call "1\\1-\\$"
  when ?.
    append.call ":03--::\\"
    append.call ":,"
    append.call "1\\1-\\$"
  when ?,
    append.call ":02--"
    append.call "~@"
    append.call "1\\\\$"
  when ?>
    append.call "01--"
  when ?<
    append.call "1-:01--?@"
  when ?[
    t = x
    append.call "v            >1\\1-\\$"
    x = t
    stack.push y
    y = code.size
    code.push []
    append.call ">:03--::\\"
    append.call          "::/?^1\\1-\\$"
  when ?]
    y = stack.pop
    append.call ">"
  end
end
append.call "0@"
code.each{ |line| puts line.map{ |c| c || " " }.join }

__END__

Tape isn't limited in positive direction. Going negative exits with 255.
Reading from EOF stdin results in exit with undefined code.
Brainfuck code isn't validated, i.e. invalid usage of [ and ] leads to undefined behaviour.

$ echo "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++." | ruby bf_translator.rb > temp
$ wc -c temp
2017
$ rasel temp
Hello World!

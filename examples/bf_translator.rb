x = y = 0
code = [[]]
stack = []
append = ->str{ str.chars{ |c| code[y][x] = c; x += 1 } }
append.call "3"
e = $<.read.delete("^-+<>[].,").each_char
optim = lambda do |c|
  n = 1
  (e.next; n += 1) while c == (e.peek rescue StopIteration)
  a, b = n.divmod(35)
  [*([35]*a), b].map{ |d| "#{d.to_s 36}-".upcase unless d.zero? }.join
end
loop do
  case e.next
  when ?-
    append.call ":::\\"
    append.call "#{optim.call ?-}G1G//%"
    append.call "1\\1-\\$"
  when ?+
    append.call ":::\\"
    append.call "0#{optim.call ?+}-G1G//%"
    append.call "1\\1-\\$"
  when ?.
    append.call ":::\\"
    append.call ":,"
    append.call "1\\1-\\$"
  when ?,
    append.call ":~@"
    append.call "1\\1-\\$"
  when ?>
    append.call "01--"
  when ?<
    append.call ":3-?@1-"
  when ?[
    t = x
    append.call "v        >1\\1-\\$"
    stack.push [x,y]
    x = t
    until code.size == y += 1
      code[y].insert x,   " " if code[y].size > x
      code[y].insert x+9, " " if code[y].size > x+9
    end
    y = code.size
    code.push []
    append.call ">:::\\::/?^1\\1-\\$"
  when ?]
    x,y = stack.pop
  end
end
append.call "0@"
code.each{ |line| puts line.map{ |c| c || " " }.join }

__END__

Tape isn't limited in positive direction. Going negative exits with 255.
Reading from EOF stdin results in exit with undefined code.
Brainfuck code isn't validated, i.e. invalid usage of [ and ] leads to undefined behaviour.

$ echo "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++." | ruby bf_translator.rb > temp
$ rasel temp
Hello World!

$ wc -c temp
1052
$ cat temp
3:::\08--G1G//%1\1-\$v        >1\1-\$01--01--:::\:,1\1-\$01--:::\3-G1G//%1\1-\$:::\:,1\1-\$:::\07--G1G//%1\1-\$:::\:,1\1-\$:::\:,1\1-\$:::\03--G1G//%1\1-\$:::\:,1\1-\$01--01--:::\:,1\1-\$:3-?@1-:::\1-G1G//%1\1-\$:::\:,1\1-\$:3-?@1-:::\:,1\1-\$:::\03--G1G//%1\1-\$:::\:,1\1-\$:::\6-G1G//%1\1-\$:::\:,1\1-\$:::\8-G1G//%1\1-\$:::\:,1\1-\$01--01--:::\01--G1G//%1\1-\$:::\:,1\1-\$01--:::\02--G1G//%1\1-\$:::\:,1\1-\$0@
                     >:::\::/?^1\1-\$01--:::\04--G1G//%1\1-\$v        >1\1-\$01--:::\01--G1G//%1\1-\$01--:::\01--G1G//%1\1-\$01--:::\1-G1G//%1\1-\$01--01--:::\01--G1G//%1\1-\$v        >1\1-\$:3-?@1-:::\1-G1G//%1\1-\$
                                                             >:::\::/?^1\1-\$01--:::\02--G1G//%1\1-\$01--:::\03--G1G//%1\1-\$01--:::\03--G1G//%1\1-\$01--:::\01--G1G//%1\1-\$:3 -?@1-:3- ?@1-:3-?@1-:3-?@1-:::\1-G1G//%1\1-\$
                                                                                                                                                                               >:::\::/?^1\1-\$:3-?@1-

$ echo "[[[]-]]-[]" | ruby examples/bf_translator.rb
3v        >1\1-\$:::\1-G1G//%1\1-\$v        >1\1-\$0@
 >:::\::/?^1\1-\$v        >1\1-\$
                 >:::\::/?^1\1-\$v         > 1\1-\$:::\1-G1G//%1\1-\$
                                 >: ::\::/?^ 1\1-\$
                                   >:::\::/?^1\1-\$

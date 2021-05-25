# RASEL (Random Access Stack Esoteric Language) v1

A programming language inspired by Befunge where instead of the program space random access you have the ability to swap with the Nth value in stack.

This repository includes [specification](#reference-specification), [examples](examples), [executable](bin/rasel) and [library](lib/rasel.rb), its [tests](test.rb) and [Github Action](.github/workflows/test.yaml) that runs them automatically.

## Usage

### Install

```
gem install rasel
```

### Run

To run a program you can either use the executable and pass a source file as argument:
```bash
echo '"olleh",,,,,A,@' > temp.rasel
rasel temp.rasel
```
Or pipe the source code directly:
```bash
echo '"olleh",,,,,A,@' | rasel
```
Or pass it as a String arg in Ruby runtime:
```ruby
require "rasel"
puts RASEL('"olleh",,,,,@').stdout.string
```
To run a program and feed it some stdin you can either put it to a file:
```bash
rasel my_program.rasel < my_input.txt
```
Or pipe it too:
```bash
echo 5 | rasel examples/factorial.rasel
echo 5 | rasel examples/fibonacci.rasel
```
Environment variable `DEBUG` makes it print the current instruction, stack and stringmode like this:
```none
["&", false, []]
[":", false, [10]]
["?", false, [10, 10]]
["1", false, [10]]
["-", false, [10, 1]]
[":", false, [9]]
...
```

## Reference specification

* Every "error raised" in this specification mean it should halt the program with any (depends on the implementation) [exit status code](https://en.wikipedia.org/wiki/Exit_status) from 1 to 255. The only currently known undefined things are how float numbers are printed (TODO: maybe implement the ability to specify precision?) and how empty source file is treated. If you find anything else missing, please report.
* Programs are read as ASCII-8BIT lines splitted by 0x0A character. For every source code line trailing space characters are trimmed and then readded to reach the length defined by the highest x coordinate of any (including invalid) non-space character in the whole source file. Lines with no non-space characters at the end of the source file are trimmed. After the source code load the program space is effectively a rectangle of NxM characters that has at least one non-space character in the last column and in the last row. Space characters are [nop](https://en.wikipedia.org/wiki/NOP_(code))s when not in the "stringmode". All other characters that are not defined in the specification raise an error if the instruction pointer reaches them unless the previous instruction was "trampoline" so it's just skipped.
* Stack data type is [Rational](https://en.wikipedia.org/wiki/Rational_data_type). Numerators and denominators are bignums, i.e. there should be no [rounding errors](https://en.wikipedia.org/wiki/Round-off_error). The "is integer" in this specification means "does not have a [fractional part](https://en.wikipedia.org/wiki/Fractional_part)".
* "Popping a value" means taking out the top value from the stack and using it in the instruction that initiated the popping. When stack is empty popping from it creates 0. For language user it should be effectively indistinguishable if the stack is empty or just has several 0 left in it.
* Instructions:
  * `@` -- exit with code popped from the stack  
    If the value isn't integer and isn't within 0..255 the error is raised.
  * `"` -- toggle "stringmode" (by default is off)  
    In this mode all instruction and invalid (i.e. having no meaning as an instruction) characters are pushed onto the stack as a corresponding number from ASCII table.  
    In this mode space character (that is nop by default) is treated as an instruction to push the value 32 onto the stack.
  * `#` -- "trampoline" -- the character under the next instruction pointer position will be ignored  
    If it's the last character on the source code line the first character on the other side of the line will be skipped.  
    If it's the last instruction on the source code line but not the last character (i.e. there are spaces or invalid characters filling it to the edge of the program space rectangle) the next character will the ignored, not from the other side of the rectangle.  
    Same about source code columns and in both directions.
  * `0`..`9`, `A`..`Z` -- push single [Base36](https://en.wikipedia.org/wiki/Base36) digit value onto the stack
  * `$` -- "discard" -- pop a value and do nothing with it
  * `:` -- "duplicate" -- pop a value and add it back to the stack twice
  * `\` -- "swapn" -- pop a value N from the stack, then swap the next one with the N+1th  
    If N isn't an integer the error is raised.  
    If N is 0 or negative then nothing swaps and it's effectively the same as `$`.  
    If N exceeds the current depth of the stack then the stack is extended with zeros as much as needed.
  * `>`, `<`, `^`, `v` -- set instruction pointer direction
  * `-`, `/`, `%` -- pop two values and push the result of an arithmetic operation  
    If divisor or modulus is 0 it's not an error and result is 0.
  * `.` -- pop a value and print it as a number  
    Print as an integer or as a float if there is a fractional part.
  * `,` -- pop a value and print it as a corresponding ASCII char  
    If the value isn't an integer within 0..255 the error is raised.
  * `~` -- read character from STDIN, put its ASCII code onto the stack and work as "trampoline" unless EOF  
    EOF does not put anything onto the stack.
  * `&` -- read Base10 non-negative integer from STDIN, put it onto the stack and work as "trampoline" unless EOF  
    EOF does not put anything onto the stack.  
    Leading non-digit characters are omitted -- that allows to consecutively read numbers that have any non-digits characters in between.
  * `j` -- "jump forward" -- pop a value from the stack and jump over that many cells in the current instruction pointer direction  
    If the value isn't integer the error is raised.  
    If the value is negative, jump is done the opposite direction but the instruction pointer direction does not change.
  * `?` -- "if positive" -- pop a value and work as "trampoline" if it's positive

## Not all but the main differences from Befunge-93/98

* stack and program space ("playfield" in [Befunge-93](https://github.com/catseye/Befunge-93) terminology) have no size limits
* stack data type is Rational
* instructions that are added
  * `A`..`Z` (case sensitive Base36)  
    push an integer from 10 to 35 onto the stack
  * `j` ("jump forward" from Funge-98)
* instruction `\` ("swapn" -- the Random Access thing)
  pop a value N from the stack and swap the next one with the N+1th
* instructions `|` and `_` are replaced with a single instruction `?` that tests if the value is positive
* instructions that are removed
  * `?` (move to a random direction)
  * `+` and `*` (addition and multiplication)  
    can be easily emulated using `-` and `/` (subtraction and division), removed just for the fun of it
  * `` ` `` and `!` ("if greater" and "logical negation")  
    can be easily emulated using other instructions
  * `p` and `g` (put and get)  
    random stack access makes self-modification almost useless and simplifies the implementation because the program space won't expand, also it might be easier for optimization

## Examples (more [here](examples))

### Factorial ([OEIS A000142](https://oeis.org/A000142))

```
1&$:?v:1-3\$/1\
     >$11\/.A,@
```

### Fibonacci ([OEIS A000045](https://oeis.org/A000045))

```
1&-:?v2\:2\01\--2\
     >$.A,@
```

### Project Euler's [Problem 1 "Multiples of 3 and 5"](https://projecteuler.net/problem=1)

```
&>:?v1-::3%1\5%/ ?v
 ^  >--.@j5\1--\3:<
```

### How do we check if the value is 0 if we have only the instruction that checks if it is positive?

The naive approach would be to check if it is not positive and then additionally negate the value and check again. Here we make a list of values -2, -1, 0, +1, +2 and then check them:
```
2-01-012 5>  :?@1-1\    :?v$     v
                          >01\-?vv
          ^  ,,,,,"true"A       <
          ^ ,,,,,,"false"A       <
```
```
$ rasel examples/naive_if_zero.rasel
false
false
true
false
false
```
Then we can apply the idea that if you multiply the negative value by itself it will become positive or just remain 0. Of course we don't have the "multiply" instruction but the "divide" effectively works the same for us (and it does not raise an error when we divide by 0):
```
2-01-012 5>  :?@1-1\    :/?vv

          ^  ,,,,,"true"A  <
          ^ ,,,,,,"false"A  <
```
This is 2-3 times shorter.

## Breaking change note

Initial version of RASEL was v0. The v1 introduced the "swapn" and deprecated the "take at".

## Outdated (v0) examples

### AdventOfCode 2020 1 1 solution

Befunge-93 (by @fis):
```befunge
1+:#v&\fp
   0>$1-:00p>:#v_00g
               >:fg00gfg+'-:*5--#v_fg00gfg*.@
            ^                  -1<
```
RASEL:
```
&v
 >2v        >$$$
   >01--:a:?^:4a0\--05--F/F/9/1-:/?v$
                                   >\$1\//.@
```
Here you can see that it's about the same size. Absence of `+` and `*` is compensated by `a`.

## TODO

- [x] some examples
- [x] [gemify](https://rubygems.org/gems/rasel)
- [x] [page at esolangs.org](esolangs.org/wiki/rasel)
- [x] [announce](https://www.reddit.com/r/esolangs/comments/lsjmrq/rasel_random_access_stack_esoteric_language/)
- [x] minimal instruction set enough for random write
- [x] implementation, tests and docs
  - [x] non-instructional
  - [x] executable
  - [x] instructional
    - [x] old
      - [x] `"`, `#`
      - [x] `0`..`9`
      - [x] `$`, `:`, `\`
      - [x] `>`, `<`, `^`, `v`
      - [x] `-`, `/`, `%`
      - [x] `.`, `,`
    - [x] changed
      - [x] `@`
      - [x] `~`, `&`
      - [x] `?`
      - [x] `\`
    - [x] new
      - [x] `A`..`Z`
      - [x] `j`
      - [ ] TODO: maybe something about additional stacks

## Development notes

When using jruby you should set env var `CI` to bundle and run tests avoiding the `gem ruby-prof` installation failure.

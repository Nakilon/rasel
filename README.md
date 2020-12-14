# RASEL (Random Access Stack Esoteric Language)

A programming language inspired by Befunge.  
(Currently only Read is random. Write is still possible only to the top of the stack.)

This repository includes the [documenation](#reference-specification), [examples](examples), Ruby-based [interpreter](lib/rasel.rb), its [tests](test.rb) and [Github Action](.github/workflows/test.yaml) that runs them automatically.

## This implementation usage

(right now the gem is in the development stage and is not published yet so you need to git clone it)

Install:
```
gem install rasel
```
Now to print 'hello\n' and exit with 0 status code you can either use the executable to run a source file:
```bash
echo '"olleh",,,,,A,@' > temp.rasel
rasel temp.rasel
```
Or pipe it:
```bash
echo '"olleh",,,,,A,@' | rasel
```
Or call it from Ruby:
```ruby
require "rasel"
puts RASEL('"olleh",,,,,@').stdout.string
```
To run a program and feed it an input from a file:
```bash
rasel program.rasel < input.txt
```

## Reference specification

* All the "errors raised" in this specification mean it should halt the program with any (depends on the implementation) [exit status code](https://en.wikipedia.org/wiki/Exit_status) from 1 to 255. The only undefined things in this specification are how float numbers are printed (TODO: maybe implement the ability to specify precision?) and how empty source file is treated. If you find anything else missing, please report since it should be defined.
* Programs are read as ASCII-8BIT lines splitted by 0x0A character. For every source code line trailing space characters are trimmed and then readded to reach the length defined by the highest x coordinate of any (including invalid) non-space character in the whole source file. Lines with no non-space characters at the end of the source file are trimmed. After the source code load the program space is effectively a rectangle of NxM characters that has at least one non-space character in the last column and in the last row too. Space characters are [nop](https://en.wikipedia.org/wiki/NOP_(code))s when not in the "stringmode". All other characters that are not defined in the specification raise an error if the instruction pointer reaches them unless the previous instruction was "trampoline" so it's just skipped.
* Stack data type is [Rational](https://en.wikipedia.org/wiki/Rational_data_type). Numerators and denominators are bignums, i.e. there should be no [rounding errors](https://en.wikipedia.org/wiki/Round-off_error). The "is integer" in this specification means "does not have a [fractional part](https://en.wikipedia.org/wiki/Fractional_part)".
* "Popping a value" means taking out the top value from the stack and using it in the instruction that initiated the popping. When stack is empty popping from it supplies 0. For language user it should be effectively indistinguishable if the stack is empty or just has several 0 left it in.
* Instructions:
  * `@` -- exit with code taken from the stack  
    If the value isn't integer and isn't within 0..255 the error is raised.
  * `"` -- toggle "stringmode" (by default is off)  
    In this mode all instruction and invalid (i.e. having no meaning as an instruction) characters are pushed onto the stack as a corresponding number from ASCII table.  
    In this mode space character (that is nop by default) is treated as an instruction to push the value 32 onto the stack.
  * `#` -- "trampoline" -- the character under the next instruction pointer position will be ignored  
    If it's the last character on the source code line the first character on the other side of line will be skipped.  
    If it's the last instruction on the source code line but not the last character (i.e. there are spaces or invalid characters filling it to the edge of the program space rectangle) the ignored character will be the next character on this line, not some character on the other side of it.  
    Same about source code columns and in both directions.
  * `0`..`9`, `A`..`Z` -- push single [Base36](https://en.wikipedia.org/wiki/Base36) digit value onto the stack
  * `$` -- "discard" -- pop a value and do nothing with it
  * `:` -- "duplicate" -- pop a value and add it back to the stack twice
  * `\` -- "swap" -- pop a value twice and put them back in reverse order
  * `>`, `<`, `^`, `v` -- set instruction pointer direction
  * `-`, `/`, `%` -- pop two values and push the result of an arithmetic operation  
    If divisor or modulus is 0 it's not an error and result is 0.
  * `.` -- pop a value and print it as a number  
    Print as integer or as float if there is a fractional part.
  * `,` -- pop a value and print it as a char of the corresponding ASCII code  
    If the value isn't an integer within 0..255 the error is raised.
  * `~` -- read character from STDIN and put its ASCII code onto the stack  
    EOF reverses the direction of the instruction pointer and does not put anything onto the stack.
  * `&` -- read Base10 non-negative integer from STDIN and put onto the stack  
    EOF reverses the direction of the instruction pointer and does not put anything onto the stack.  
    Leading non-digit characters are omitted -- that allows to consecutively read numbers that have any non-digits characters in between.
  * `j` -- "jump forward" -- pop a value from the stack and jump over that many cells in the current instruction pointer direction  
    If the value isn't integer the error is raised.  
    If the value is negative, jump is done the opposite direction but the instruction pointer direction does not change.
  * `?` -- "if" -- pop a value and do nothing if it's positive  
    Reverse the direction of the instruction pointer if it's negative or 0.
  * `a` -- "take at" -- pop a value N from the stack, then copy the Nth value from it to the top  
    If the top stack value is 0 or exceeds the size of stack then it's effectively the same as `$0`.  
    If the top stack value is 1 it's effectively the same as `$:`.  
    If the top stack value is negative or is not integer the error is raised.

## Not all but the main differences from Befunge-93/98

* `@` pops an exit status code from the stack (like `q` in [Funge-98](https://github.com/catseye/Funge-98))
* stack and program space ("playfield" in [Befunge-93](https://github.com/catseye/Befunge-93) terminology) have no size limits
* stack data type is Rational
* instructions that are added
  * `A`..`Z` (case sensitive Base36)  
    push an integer from 10 to 35 onto the stack
  * `j` ("jump forward" from Funge-98)
  * `a` ("take at" -- the Random Access thing)  
    pop a value N from the stack and duplicate the Nth value from the stack onto its top
* instructions `|` and `_` are replaced with a single instruction `?` that reverses current direction if the popped value is not positive
* instructions that are removed
  * `?` (move to random direction)  
    because it wasn't much needed
  * `+` and `*` (addition and multiplication)  
    can be easily emulated using `-` and `/` (subtraction and division), removed just for the fun of it
  * `` ` `` and `!` ("if greater" and "logical negation")  
    can be easily emulated using other instructions
  * `p` and `g` (put and get)  
    random stack access should make self-modification almost useless and simplify the implementation because program won't expand, also it might be easier for optimization

## Examples (more [here](examples))

### How do we check if the value is 0 if we have only the instruction that checks if it is positive?

The naive approach would be to check if it is not positive and then additionally negate the value and check again. Here we make a list of values -2, -1, 0, +1, +2 and then check them:
```
2-01-012 5> :#@?1-\     :#v?$    v
                          >0\-#v?v
          ^  ,,,,,"true"A      <
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
2-01-012 5> :#@?1-\     :/#v?v

          ^  ,,,,,"true"A  <
          ^ ,,,,,,"false"A   <
```
It became 2-3 times shorter but now we realise that after the division the value is either 0 or 1 so we can utilize the "jump" instruction to make it even shorter:
```
2-01-012 5> :#@?1-\     :/jvv

          ^  ,,,,,"true"A  <
          ^ ,,,,,,"false"A  <
```

### AdventOfCode 2020 1 1 non-golfed solution

Befunge-93 (by @fis):
```befunge
1+:#v&\fp
   0>$1-:00p>:#v_00g
               >:fg00gfg+'-:*5--#v_fg00gfg*.@
            ^                  -1<
```
RASEL:
```
&#v
  >2v        >$$$
    >01--:a:#^?:4a0\--05--F/F/9/1-:/jv$
                                     >\$1\//.@
```
Here you can see that it's about the same size. Absence of `+` and `*` is compensated by `a`.

## TODO

- [x] some examples
- [ ] page at esolangs.org
- [ ] announcement
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
    - [x] new
      - [x] `A`..`Z`
      - [x] `j`
      - [x] `a`
      - [ ] TODO: maybe something about additional stacks

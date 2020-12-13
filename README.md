[![Test](https://github.com/Nakilon/rasel/workflows/.github/workflows/test.yaml/badge.svg)](https://github.com/Nakilon/rasel/actions)

# RASEL (Random Access Stack Esoteric Language)

A programming language inspired by Befunge-93.

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

## Reference specification

* All the "errors raised" in this specification mean it should halt the program with any (depends on the implementation) [exit status code](https://en.wikipedia.org/wiki/Exit_status) from 1 to 255. The only undefined things in this specification are how float numbers are printed (TODO: maybe implement the ability to specify precision?) and how empty source file is treated. If you find anything else missing, please report since it should be defined.
* Programs are read as ASCII-8BIT lines splitted by 0x0A character. For every source code line trailing space characters are trimmed and then readded to reach the length defined by the highest x coordinate of any (including invalid) non-space character in the whole source file. Lines with no non-space characters at the end of the source file are trimmed. After the source code load the program space is effectively a rectangle of NxM characters that has at least one non-space character in the last column and in the last row too. Space characters are [nop](https://en.wikipedia.org/wiki/NOP_(code))s when not in the stringmode. All other characters that are not defined in the specification raise an error if the instruction pointer reaches them unless the previous instruction was "trampoline" so it's just skipped.
* Stack and program space data type is [Rational](https://en.wikipedia.org/wiki/Rational_data_type). Numerators and denominators are bignums, i.e. there should be no [rounding errors](https://en.wikipedia.org/wiki/Round-off_error).
* "Popping a value" means taking out the top value from the stack and using it in the instruction that initiated the popping. When stack is empty popping from it supplies 0. For language user it should be effectively indistinguishable if the stack is empty or has several 0 it in.
* Instructions:
  * `@` -- exit with code taken from the stack  
    If value isn't integer and isn't within 0..255 the error is raised.
  * `"` -- toggle "stringmode" (by default is off)  
    In this mode all instruction and invalid (i.e. having no meaning as an instruction) characters are pushed onto the stack.  
    In this mode space character (that is nop by default) is treated as an instruction to push the value 32 onto the stack.
  * `#` -- "trampoline" -- the character under the next instruction pointer position will be ignored  
    If it's the last character on the source code line the first character on the other side of line will be skipped.  
    If it's the last instruction on the source code line but not the last character (i.e. there are spaces filling it to the edge of the program space rectangle) the ignored character will be the next filling space, not some character on the other side of the line.  
    Same about source code columns and in both directions.
  * `0`..`9`, `A`..`Z` -- push single [Base36](https://en.wikipedia.org/wiki/Base36) digit value onto the stack
  * `$` -- "discard" -- pop a value and do nothing with it
  * `:` -- "duplicate" -- pop a value and add it back to the stack twice
  * `\` -- "swap" -- pop a value twice and put them back in reverse order
  * `>`, `<`, `^`, `v` -- set instruction pointer direction
  * `-`, `/`, `%` -- pop two values and push the result of an arithmetic operation  
    If divisor or modulus is 0 it's not an error and result is 0.
  * `.` -- pop a value and print it as a number  
    Print as integer or as float if there is a [fractional part](https://en.wikipedia.org/wiki/Fractional_part).
  * `,` -- pop a value and print it as a char of the corresponding ASCII code  
    If value isn't integer and isn't within 0..255 the error is raised.
  * `~` -- read character from STDIN and put onto the stack  
    EOF reverses the direction of the instruction pointer and does not put anything onto the stack.
  * `&` -- read Base10 non-negative integer from STDIN and put onto the stack  
    EOF reverses the direction of the instruction pointer and does not put anything onto the stack.  
    Leading non-digit characters are omitted -- that allows to consecutively read numbers that have any non-digits characters in between.
  * `j` -- "jump forward" -- pop a value from the stack and jump over that many cells in the current instruction pointer direction  
    If value isn't integer the error is raised.  
    If value is negative, jump is done the opposite direction but the instruction pointer direction does not change.
  * `|`, `_` -- "go north if", "go west if"  
    Set instruction pointer direction to north or west if the popped value is positive, south and east otherwise.  
    0 is not positive.

## Main differences from Befunge-93

* `@` pops the exit status code from the stack (like `q` in [Funge-98](https://github.com/catseye/Funge-98))
* any unknown character (i.e. not an instruction, space or newline) while not in stringmode raises an error
* reading EOF from STDIN works as "Reverse" instruction (like in Funge-98)
* stack and program space ("playfield" in [Befunge-93](https://github.com/catseye/Befunge-93) terminology) have no size limits
* stack and program space data type is Rational
* `|` and `_` instead of checking if the popped value is zero now check if it's positive
* instructions that are added
  * `A`..`Z` (case sensitive Base36)  
    push an integer from 10 to 35 onto the stack
  * `j` ("jump forward" from Funge-98)
  * `a` ("take at" -- the Random Access thing)  
    pop a value N from the stack and duplicate the Nth value from the stack onto its top
* instructions that are removed
  * `+` and `*` (addition and multiplication)  
    can be easily emulated using `-` and `/` (subtraction and division), removed just for the fun of it
  * `` ` `` (if greater)  
    can be easily emulated using `-` and new `|` and `_`
  * `!` (logical negation)
    can be emulated too
  * `?` (move to random direction)  
    because it wasn't much needed
  * `p` and `g` (put and get)  
    random access should make self-modification almost useless and simplify the implementation because program won't expand, also in theory it's easier for optimization

## TODO

- [ ] page at esolangs.org
- [ ] some examples
- [ ] announcement
- [ ] implementation, tests and docs
  - [x] executable
  - [x] non-instructional
  - [ ] instructional
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
      - [x] `|`, `_`
    - [ ] new
      - [x] `A`..`Z`
      - [x] `j`
      - [ ] `a`
      - [ ] TODO: maybe something about additional stacks

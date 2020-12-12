[![Test](https://github.com/Nakilon/rasel/workflows/.github/workflows/test.yaml/badge.svg)](https://github.com/Nakilon/rasel/actions)

# RASEL (Random Access Stack Esoteric Language)

A programming language inspired by Befunge-93.

## Differences from Befunge-93

* `@` pops the exit code from the stack
* any unknown character (i.e. not an instruction, space or newline) while not in stringmode throws an exception
* reading EOF from STDIN works as "Reverse" instruction (like in [Funge-98](https://github.com/catseye/Funge-98))
* stack and program space ("playfield" in [Befunge-93](https://github.com/catseye/Befunge-93) terminology) have no size limits
* stack data type is [Rational](https://en.wikipedia.org/wiki/Rational_data_type)  
  numerators and denominators are bignums, i.e. there should be no [rounding errors](https://en.wikipedia.org/wiki/Round-off_error)
* `|` and `_` instead of checking if the popped value is zero now check if it's positive
* instructions that are added
  * `A`..`Z` (case sensitive [Base36](https://en.wikipedia.org/wiki/Base36))  
    push an integer from 10 to 35 onto the stack
  * `j` ("jump forward" from Funge-98)  
    pop a value N from the stack and jump over N cells in the current direction
  * `a` ("take at" -- the Random Access thing)  
    pop a value N from the stack and duplicate the Nth value from the stack onto its top
* instructions that are removed
  * `+` and `*` (addition and multiplication)  
    can be easily emulated using `-` and `/` (subtraction and division), removed just for the fun of it
  * `` ` `` (if greater)  
    can be easily emulated using `-` and new `|` and `_`
  * `?` (move to random direction)  
    because it wasn't much needed
  * `p` and `g` (put and get)  
    random access should make self-modification almost useless and simplify the implementation because program won't expand, also in theory it's easier for optimization

## Reference specification

* All the errors raised according to this specification should halt the program with any (depends on the implementation) non-0 exit code. The only undefined things in this specification are how float numbers are printed and how empty source file is treated. If you find anything else missing, please report since it should be defined.
* Programs are read as ASCII-8BIT lines splitted by 0x0A character. For every source code line trailing space characters are trimmed and then readded to reach the length defined by the highest x coordinate of any (including invalid) non-space character in the whole source file. Lines with no non-space characters at the end of the source file are trimmed. After the source code load the program space is effectively a rectangle of NxM characters that has at least one non-space character in the last column and in the last row too. Space characters are [nop](https://en.wikipedia.org/wiki/NOP_(code))s when not in the stringmode. All other characters that are not defined in the specification raise an error if the instruction pointer reaches them.
* Instructions:
  * `"` -- toggle "stringmode" (by default is off)  
    In this mode space character (that is nop by default) is treated as an instruction to push the value 32 onto the stack.

## TODO

- [ ] page at esolangs.org
- [ ] some examples
- [ ] announcement
- [ ] implementation, tests and docs
  - [ ] executable
  - [x] non-instructional tests
  - [ ] instructional
    - [ ] old
      - [x] `"`
      - [ ] `0`..`9`
      - [ ] `$`, `:`, `\`
      - [ ] `#`
      - [ ] `>`, `<`, `^`, `v`
      - [ ] `-`, `/`, `%`
      - [ ] `,`, `.`
      - [ ] `!`
    - [ ] changed
      - [ ] `@`
      - [ ] `~`, `&`
      - [ ] `|`, `_`
    - [ ] new
      - [ ] `A`..`Z`
      - [ ] `j`
      - [ ] `a`
      - [ ] something about additional stacks maybe

## Development notes

Alpine packaged and dockerized rubies:

    packages    ruby docker hub
    3.12 2.7.1               2.5.8 2.6.6 2.7.1
    3.11 2.6.6        2.4.10 2.5.8 2.6.6 2.7.1
    3.10 2.5.8        2.4.10 2.5.8 2.6.6 2.7.1
    3.9  2.5.8        2.4.9  2.5.7 2.6.5 2.7.0p1
    3.8  2.5.8  2.3.8 2.4.6  2.5.5 2.6.3
    3.7  2.4.10 2.3.8 2.4.5  2.5.3 2.6.0
    3.6  2.4.6        2.4.5  2.5rc
    3.5  2.3.8
    3.4  2.3.7  2.3.7 2.4.4
    3.3  2.2.9

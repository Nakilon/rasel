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

## TODO

- [ ] page at esolangs.org
- [ ] some examples
- [ ] announcement
- [ ] implementation
  - [ ] executable
  - [ ] non-instructional tests
  - [ ] instructional tests and docs
    - [ ] old
      - [ ] `"`
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

## Reference (specification)

This reference does not describe fundamental (i.e. terms and the runtime process) that you are supposed to already know as funge family languages basics.

TODO

The only undefined (i.e. depends on the implementation) behaviour is printing a float. Otherwise any action that is not in this specification should raise an error (halt the program).

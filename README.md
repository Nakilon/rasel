# RASEL (Random Access Stack Esoteric Language)

A programming language mostly similar to Befunge-93 but with the following changes to simplify its usage:

* reading EOF from STDIN pushes -1 onto stack
* program space ("playfield" in Befunge-93 terminology) has no limits
* cell data type is [Rational](https://en.wikipedia.org/wiki/Rational_data_type)  
  numerators and denominators are bignums, i.e. there should be no [rounding errors](https://en.wikipedia.org/wiki/Round-off_error)
* several commands are added
  * `A`..`Z` (case sensitive [Base36](https://en.wikipedia.org/wiki/Base36))  
    push an integer from 10 to 35 onto the stack
  * `j` ("jump forward" from [Funge-98](https://github.com/catseye/Funge-98))  
    pop a value N from the stack and jump over N cells in the current direction
  * `a` ("take at" -- the Random Access thing)  
    pop a value N from the stack and duplicate the Nth value from the stack onto its top
* several commands are removed  
  * `?` (move to random direction)  
    because it wasn't much needed
  * `+` and `*` (addition and multiplication)  
    can be emulated with `-` and `/` (subtraction and division), removed just for fun of a low cost alphabet minimization
  * `p` and `g` (put and get)  
    random access should make self-modification almost useless and simplify the implementation because program won't expand, also easier for optimization

## TODO:

- [ ] implementation (each includes test(s))
  - [ ] Befunge-93 part of the language
  - [ ] `A`..`Z`
  - [ ] `j`
  - [ ] `a`
- [ ] page at esolangs.org
- [ ] some examples

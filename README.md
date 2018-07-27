# blips
Esoteric lisp runtime using filesystem as memory.

Some things are stupid because they won't work. Other things are stupid because they might. This project is one of the latter. 

After a discussion that ranged from esoteric languages, through lisp, and many other things, 
the general question arose 'Has anyone done an esoteric implementation of a mainstream language?' and from there the specific question of whether you could implement lisp using a *nix file system as the memory. 
Lisp binding implemented as symbolic links. Strings and other values as files, Conses as directories with two symbolic links called car and cdr. Etc. 
Stupid yet plausible. So naturally the question must be answered. This project does that.

It is an extremely minimal implementation of a lisp runtime. Just sufficiently complete to run a particular recursive 'towers of hanoi' program.

It has a garbage collector, REPL and implements a few built in functions and forms. 

## Environment

This runs on MAC-OS and Linux.

## Running

```
MacBook-Pro:blips bruce$ ./blips.sh
?: (print (+ 3 4))
7
=7
?: (+ 3 4)
=7
?: (car (quote (1 2 3)))
=1
?: (load "hanoi.lsp")
=move1
?: (hanoi 3)
((1 2 3) nil nil)
((2 3) (1) nil)
((3) (1) (2))
((3) nil (1 2))
(nil (3) (1 2))
((1) (3) (2))
((1) (2 3) nil)
(nil (1 2 3) nil)
?: !exit
```

## Features
- Garbage Collector
- REPL
- string and int literals
- dynamic scoping
- `setq, set, eval, quote, =, not, defun, if, while, +, car, cdr, cons, print, load`


## implementation
- int values are a file called `.int_V` where `V` is the decimal value, the contents of the file are the ascii decimal value of the int.
- str values are a file called `.str_XXXX` where `XXXX` make a unique file name. The contents of the file are the contents of the string.
- cons values are a directory called `.cons_XXXX` where XXXX make a unique file name. The contents of the directory are symbolic links `car` and `cdr` pointing to the two values.
- symbols are files or symbolic links with the same name as the symbol. Bound symbols are symbolic links to the file or directory representing the bound value. Unbound symbols are zero sized files.

## Extending

To implement additional forms and functions...
- Decide on the type of implementation
  - A function has its arguments evaluated prior to being passed to the function.
  - A simple form has the un-evaluated args passed as separate parameters.
  - A complex form has all the arguments passed as a single list, that is a cons.
- create a bash function called `XXX_YYY` where `XXX` is the name of the function or form, and `YYY` is one of
  - `func_impl` to implement a function.
  - `form_impl` to implement a simple form.
  - `form2_impl` to implement a complex form.

- implement the function.
  - the result is a path (of the value), and is returned by writing to stdout of the function. (or 'nil')
  - there are utility functions for creating ints, strings and cons.
  - for a function the evaluated arguments are $1 .. $N and are the path's to the values.
  - for a simple form the unevaluated arguments are $1 .. $N and are the paths to the values.
  - for a complex form, $1 is the name of a cons (a directory) containing all the arguments as a list.
  - do not write anything other than the result to stdout.
  - output may be written to stderr.
  - see the existing definitions in `blips_functions.sh` for how the existing forms and functions are defined.
  
- If the function is in `blips_functions.sh` it will be available once the blips REPL is restarted.
- Otherwise if putting your own functions in a new file, make sure the file is sourced from `blips.sh` at the same place that the other files are sourced.


## Cheats
While most of the system is implemented using bash script and basic filesystem commands (`touch, ln, rm, mkdir, ls` and similar), the tokenizer uses `sed`, and the garbage collector uses `find`.

## Pull Requests
Will be considered if accompanied by a psychiactric report.

# Bashtest

A poor-man's clone of Python's `Pytest` library. Provides simple functionality
to perform unit testing on Bash scripts/functions. Runs on Bashtest-specific
scripts with the same principles as `Pytest`.

`Bashtest` scripts must be named beginning with `test` and ending in `.sh`, and
must contain functions whose names begin with `test`. camelCase and snake_case
are both perfectly fine for scripts and functions. The functions can contain
as many `assert` statements as needed, but will stop executing after the first
failing `assert`. The rest of the functions will continue executing. After all
`test` functions have run for all `Bashtest` scripts, all tests results will be
printed, along with a very simple traceback (it's more a report than a trace,
really) for any failing tests. If any tests for any `Bashtest` scripts failed,
`Bashtest` will return a status code of 1, otherwise a 0 is returned.

`assert` statements can be used with expressions exactly as they would be with
Bash's built-in test command (normally in single or double square brackets
like so: `[ expression ]`), so it's not necessary to learn anything new there.
Currently only **single** bracket evaluation is performed and has been tested.
`assert` statements with commands can check for success or failure, but it's
normally more useful to use them in command expansion and apply them towards
expressions. The only caveat for handling commands is that it cannot handle
pipes.

Debug mode can be enabled for a lot more information by passing `-d` as the
first argument.

## Example Usage

```
bash bashtest.sh tests_directory

bashtest.sh .

bashtest.sh test_module_1.sh test_module_2.sh [...]

bashtest.sh -d testModule1.sh testModule2.sh [...]
```

## Sample Bashtest Script

```
# test_some_module.sh


. "/some/path/some_module.sh"


testModuleFunction(){
   assert 1 = 1
   assert ! 1 = 0
   assert 1 -ne 0

   assert true
   assert ! false
   assert ! moduleFunction arg_fails
   assert moduleFunction arg_passes

   debug "moduleFunction returns: $(moduleFunction arg_fails)"

   assert "$(moduleFunction arg)" = string
   
   ...
}

test_otherFunction(){ ... }
```
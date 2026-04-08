# Bashtest

A poor-man's clone of Python's `Pytest` library. Provides simple functionality
to perform unit testing on Bash scripts/functions. Runs on Bashtest-specific
scripts with the same principles as `Pytest`.

`Bashtest` scripts must be named beginning with `test` and ending in `.sh`, and
must contain functions whose names begin with `test`. camelCase and snake_case
are both perfectly fine for scripts and functions. The functions can contain
as many `assert` statements as needed, but will stop executing after the first
failing `assert`. The rest of the functions will continue executing. After all
`test` functions have run for all `Bashtest` scripts, all test results will be
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

### Options

All options should always be listed first.

Debug mode can be enabled for a lot
more information with the `-d` option.

It is possible to specify specific tests to be run, which is helpful when
trying to narrow down the reason for a specific failing test or two in debug
mode. Otherwise debug mode puts out a lot, lot of information that becomes a
pain to sift through. Pass the `-t` option with a list of tests to run,
separated with commas like so: `test_function_1,test_function_2`.

# Examples

### At the terminal

```
# Run with specific test files.
bashtest test_module_1.sh test_module_2.sh [...]

# Find and run tests files in a directory (and subdirectories).
bashtest tests_directory

# Run in debug mode.
bashtest -d testModule1.sh testModule2.sh [...]

# Run only specific tests (in all test files). Usually only makes sense when run
# with a single file for this reason.
bashtest -d -t test_function1,test_function2 testModule.sh

```

### Sample Bashtest script

```
# test_some_module.sh


. "/some/module/to_unit_test.sh"


test_moduleFunction(){
   assert 1 = 1
   assert ! 1 = 0
   assert 1 -ne 0

   assert true
   assert ! false
   assert ! moduleFunction arg_fails
   assert moduleFunction arg_passes

   assert "$(moduleFunction arg)" = string
   assert -z "$(moduleFunction)"
   
   ...
}


test_otherFunction(){
   ...
}
```
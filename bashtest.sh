#!/usr/bin/env bash
# Jeff Cassell
# 2026APR04

# Bashtest


declare -a totalTests
declare DEBUG FAILURE


printUsage() {
   cat << EOF
Execute this script and point to a directory that contains test<name>.sh files,
or a specific test<name>.sh file.

[Examples]
bash bashtest.sh test_module.sh
bashtest.sh testModule1.sh testModule2.sh
bashtest.sh /a/directory/with/tests
EOF
   exit 1
}


# $1=expression or command
assert() {
   local args=("$@")
   local firstArg="$1"
   local numberOfArgs=$#


   __assert_is_command__() {
      ignoredCommands=("test")
      for command in "${ignoredCommands[@]}"; do
         [ "$1" = "$command" ] && echo 1 && return
      done

      command -v "$1" &> /dev/null; echo $?
   }


   __assert_simple_traceback__() {
      # Start at 2 to skip the calls to traceback() and assert().
      local message="$1"
      local index=2
      local indent="   "
      local prefix line report

      report=($(caller $index))
      echo
      echo "(${report[1]}) -> ${report[2]}"
      echo
      echo "${indent}Assertion: \"$message\""
   }


   # $1=message (optional)
   __assert_failure__() {
      local message="${1:-"${args[*]}"}"
      # [ -n "$1" ] && message="$1"
      __assert_simple_traceback__ "$message"

      [ "${0##*/}" = "bash" ] && return 1  # Running in the terminal.
      exit 1
   }


   # Handle command status codes.

   local runCommand=$(__assert_is_command__ "$firstArg")
   # For some reason '!' registers as a command, so account for that.
   [ "$firstArg" = '!' ] && runCommand=$(__assert_is_command__ "$2")

   if [ $runCommand -eq 0 ]; then
      local result

      if [ "$firstArg" = '!' ]; then
         result=$(! "${args[@]:1}")
         result=$?
      else
         result=$("${args[@]}")
         result=$?
      fi
      
      # echo result $result
      [ $result -eq 0 ] || __assert_failure__
      return
   fi

   # Handle expressions.

   case "$firstArg" in
      '!')
         # Expression is supposed to fail, but doesn't.
         [ "${args[@]}" ] || __assert_failure__
         return
         ;;
      *)
         # Expression is supposed to pass, but doesn't.
         [ "${args[@]}" ] || __assert_failure__
         return
         ;;
   esac
}


# $1=array
arraysize() {
   local -n array="$1"
   echo ${#array[@]}
}


# $1=array
arrayfilled() {
   local -n array="$1"
   [ -n "$array" ] || return
   [ ${#array[@]} -gt 0 ]
}


# $1=message
debug() {
   local message="$1"

   # If no message is provided, return the status of DEBUG.
   if [ -z "$message" ]; then
      [ -n "$DEBUG" ]
      return
   fi
   
   if [ -n "$DEBUG" ]; then
      echo >&2
      echo "$message" >&2
   fi
}


# $1=message
error() {
   local message="$1"
   echo "Error processing: $message" >&2
}


# $1=array to remove; $2=array to filter
#
# Filters any values in array 1 ($1) from array 2 ($2) and returns the resulting
# array. Used to isolate test functions that are sourced from individual test
# files from any existing functions that accidentally match.
getFilteredArray() {
   local -n removedArray="$1"
   local -n filteredArray="$2"
   local i j
   
   debug "Filtering array of size $(arraysize removedArray) from array of size \
$(arraysize filteredArray)"

   [ -n "$filteredArray" ] || return

   # Return the filter array if there is no remove array.
   if ! arrayfilled removedArray; then
      printf "%s\n" "${filteredArray[@]}"
      return
   fi
   
   local results=("${filteredArray[@]}")  # Copy so original isn't mutated.

   for i in "${!removedArray[@]}"; do
      for j in "${!results[@]}"; do

         if [ "${removedArray[$i]}" = "${results[$j]}" ]; then
            unset -v results[$j]
            break
         fi
      done
   done

   arrayfilled results && printf "%s\n" "${results[@]}"
}


# $1=tests array
cleanupTests() {
   local -n original="$1"
   local -a tests=("${original[@]}")
   local oneTest

   debug "Removing $(arraysize tests) test(s) from environment"

   arrayfilled tests || return

   for oneTest in "${tests[@]}"; do
      debug "Removing function from environment: $oneTest"
      unset -f "$oneTest"
   done
}


# $1=tests array; $2=test file
#
# Tracebacks aren't displayed if DEBUG is set, in favor of more detailed
# step-by-step feedback.
runTests() {
   local -n testsOriginal="$1"
   local tests=("${testsOriginal[@]}")
   local file="$2"
   local -a tracebacks
   local resultsLine oneTest feedback status

   local failMessage="    ===== [ FAIL ] ====="
   local   okMessage="    =====    OK    ====="

   arrayfilled tests || return

   # File must be sourced again because tests were gathered within a subprocess.
   debug "Sourcing $file to run tests"
   SAVED_ARGS=("$@")
   set --
   . "$file"
   set -- "${SAVED_ARGS[@]}"

   for oneTest in "${tests[@]}"; do
      
      debug ">>> Running: $oneTest"

      if ! command -v "$oneTest" &> /dev/null; then
         FAILURE=yes
         feedback=$(echo)
         feedback+="$test not found"
         tracebacks+=("$feedback")
         resultsLine+="F"

         debug "$feedback"
         continue
      fi

      feedback=$($oneTest 2> /dev/null)
      status=$?

      debug && echo && ($oneTest >&2)

      if [ $status = 0 ]; then
         debug "$okMessage"
         resultsLine+="."
      else
         FAILURE=yes
         debug "$failMessage"
         resultsLine+="F"
         tracebacks+=("$feedback")
      fi
   done

   totalTests+=("$file $resultsLine")
   # Only display tracebacks if there are elements and we're not debugging.
   arrayfilled tracebacks && ! debug && printf "%s\n" "${tracebacks[@]}"
}


findTests(){ declare -F | grep "declare -f test*" | awk '{print $3}'; }


# $1=test file (optional)
getTests() {
   local file="$1"
   local -a oldTests newTests filteredTests

   # Isolate any pre-existing functions that accidentally match the test
   # criteria.
   readarray -t oldTests < <(findTests)
   debug "$(arraysize oldTests) function(s) matching test naming convention in \
current environment will be excluded"

   if [ -z "$file" ]; then
      arrayfilled oldTests && printf "%s\n" "${oldTests[@]}"
      return
   fi

   [ -f "$file" ] || return
   
   # Preserve current positional arguments, then remove them, otherwise sourcing
   # a file will pass those arguments along.
   debug "Sourcing $file to gather tests"
   SAVED_ARGS=("$@")
   set --
   . "$file"
   set -- "${SAVED_ARGS[@]}"

   readarray -t newTests < <(findTests)
   debug "Gathered $(( $(arraysize newTests) - $(arraysize oldTests) )) test(s)"

   readarray -t filteredTests < <(getFilteredArray oldTests newTests)
   debug "Filtered and returning $(arraysize filteredTests) test(s)"

   arrayfilled filteredTests && printf "%s\n" "${filteredTests[@]}"
}


# $1=test file
processTestFile() {
   local file="$1"
   local -a tests

   debug "Processing test file: $file"

   readarray -t tests < <(getTests "$file")
   debug "Received $(arraysize tests) test(s) from $file"

   # Skip if no tests are found.
   if ! arrayfilled tests; then
      error "Contained no tests: $file"
      return 1
   fi

   runTests tests "$file"
   cleanupTests tests
}


# $1=directory
#
# Find test files within a directory and its subdirectories.
getTestFiles() {
   local directory="$1"
   [ -d "$directory" ] || return 1

   find "$directory" -name "test*.sh"
}


main() {
   [ -n "$1" ] || printUsage

   local -a testFiles
   local arg file

   echo
   echo "========== TESTS BEGIN =========="
   echo

   for arg in "$@"; do
      
      if [ -d "$arg" ]; then
         debug "Collecting test files from $arg"
         readarray -t testFiles < <(getTestFiles "$arg")
         debug "Collected $(arraysize testFiles) test files"

         if ! arrayfilled testFiles; then
            error "Contained no test files: $arg"
            continue
         fi

         for file in "${testFiles[@]}"; do
            processTestFile "$file" || continue
         done
      elif [ -f "$arg" ]; then
         processTestFile "$arg" || continue
      else
         echo "Invalid argument: $arg"
      fi
   done

   echo
   echo
   echo "========== TESTS COMPLETE =========="
   echo
   printf "%s\n" "${totalTests[@]}"

   [ -z "$FAILURE" ]
}


if [ "$#" -gt 0 ]; then
   if [ "$1" = "-d" ]; then
      DEBUG=true
      shift 1
   fi

   main "$@"
else
   printUsage
fi

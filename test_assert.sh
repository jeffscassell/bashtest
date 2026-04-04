test_functions(){

   _pass(){ true; }
   _fail(){ false; }
   _args() { return $1; }


   # Functions without variables.
   assert ! _fail
   assert _pass

   # Functions with variables.
   assert _args 0 5 52 1 etc
   assert ! _args 1 0 9 1 etc
}


test_emptyVariables(){
   local empty

   assert -z "$empty"
   assert ! "$empty" = 0
}


test_strings(){
   text=string

   assert -n "$text"
   assert "$text" = string
}


test_numbers(){
   number=5
   assert -n "$number"
   assert "$number" = 5
}


# Just to see what failure looks like.
test_failure(){
   assert false
   assert true  # Shouldn't get here.
}

testFunctions(){

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


testEmptyVariables(){
   local empty

   assert -z "$empty"
   assert ! "$empty" = 0
}


testStrings(){
   text=string

   assert -n "$text"
   assert "$text" = string
}


testNumbers(){
   number=5
   assert -n "$number"
   assert "$number" = 5
}


# Just to see what failure looks like.
testFailure(){
   assert false
   assert true  # Shouldn't get here.
}

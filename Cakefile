{exec} = require "child_process"

call = (command, fn) ->
  exec command, (err, stdout, stderr) ->
    if err?
      console.error "Error :"
      return console.dir   err

    fn err if fn?

task 'build', 'Compile coffee scripts into plain Javascript files', ->
  call "coffee -c *.coffee"

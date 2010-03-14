require 'chalk'

Chalk::Blackboard.url = "https://learn.eku.edu"
student = Chalk::Blackboard.login(ARGV[0], ARGV[1])
puts student.inspect

require "yaml"
require "set"
require "pp"

data = YAML.load_file("tmp/data.yml")
data["teams"].each{|team|
  team["members"] -= data["exclude"]
}

Team = Struct.new(:name, :members)

teams = data["teams"].map{|d|
  Team.new(d["name"], Set.new(d["members"]))
}

print "\xef\xBB\xBF"
puts "team1,team2,score,detail"
teams.permutation(2){|t1, t2|
  overlaps = t1.members & t2.members
  puts "#{t1.name},#{t2.name} ,#{overlaps.size},#{overlaps.to_a.join("、")}"
}

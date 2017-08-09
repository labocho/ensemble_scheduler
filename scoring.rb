require "yaml"
require "set"
require "pp"
require "byebug"

ROOMS = 4 # 部屋の数
BLOCKS = 2 # 枠数

# 数 n を max_elements に分割した組み合わせを [[Integer, ..]] で返す
# 各要素は max_number を超えない
# 組み合わせが存在しない場合 [] を返す
def split_number(n, max_number, max_elements)
  if n == 0
    return [[0] * max_elements]
  end

  if max_elements == 1
    if n > max_number
      []
    else
      [[n]]
    end
  else
    max_number.downto(1).map{|i|
      if n - i >= 0
        split_number(n - i, i, max_elements - 1).map{|a|
          [i] + a
        }
      else
        nil
      end
    }.compact.flatten(1)
  end
end

# teams を rooms で指定された各 capacity ごとに分けた組み合わせを返す
# [[[T, ...], ...], ...]
def fill_rooms(teams, rooms)
  return [[]] if rooms.size == 0
  n = rooms[0]
  c = teams.combination(n).map{|teams_in_room|
    fill_rooms(teams - teams_in_room, rooms[1..-1]).map{|a|
      [teams_in_room] + a
    }
  }.flatten(1)
  c.map{|a| Set.new(a) }.uniq.map(&:to_a)
end


# load
data = YAML.load_file("tmp/data.yml")
data["teams"].each{|team|
  team["members"] -= data["exclude"]
}

Team = Struct.new(:name, :members)

teams = data["teams"].map{|d|
  Team.new(d["name"], Set.new(d["members"]))
}

result = []

print "\xef\xBB\xBF"
puts "score,#{1.upto(BLOCKS).map{|i| "block#{i}" }.join(",")}"

split_number(teams.size, ROOMS, BLOCKS).each{|rooms|
  fill_rooms(teams, rooms).each do |teams_in_rooms|
    score = 0
    teams_in_rooms.each{|teams_in_room|
      teams_in_room.combination(2).each do |t1, t2|
        # 被ってる延べ人数
        score -= (t1.members & t2.members).size
      end
    }
    result << {score: score, teams_in_rooms: teams_in_rooms}
    puts "#{score},#{teams_in_rooms.map{|teams| teams.map(&:name).join(" / ") }.join(", ")}"
  end
}


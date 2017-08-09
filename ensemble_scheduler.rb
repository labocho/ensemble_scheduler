#!/usr/bin/env ruby
require "thor"
require "yaml"
require "set"
require "csv"

module EnsembleScheduler
  UTF8BOM = "\xef\xBB\xBF"

  class CLI < Thor
    desc "conflict FILE", "Show member conflicts for each team combinations"
    def conflict(file)
      teams = Team.load(file)

      print UTF8BOM
      csv = CSV.new($stdout)
      csv << ["team1", "team2", "score", "detail"]
      teams.permutation(2){|t1, t2|
        overlaps = t1.members & t2.members
        csv << [t1.name, t2.name, overlaps.size, overlaps.to_a.join("、")]
      }
    end

    desc "score FILE ROOMS BLOCKS", "Show score for all schedule"
    def score(file, rooms, blocks)
      teams = Team.load(file)
      rooms = rooms.to_i
      blocks = blocks.to_i

      Scorer.new.score(teams, rooms,  blocks)
    end

    desc "teams FILE", "Show members of teams"
    def teams(file)
      teams = Team.load(file).sort_by(&:name)


      print UTF8BOM
      csv = CSV.new($stdout)
      csv << ["member"] + teams.map(&:name)
      players = teams.flat_map{|t| t.members.to_a }.sort.uniq
      players.each do |player|
        csv << [player] + teams.map{|t| t.member?(player) ? "v" : nil }
      end
    end
  end

  Team = Struct.new(:name, :members) do
    def self.load(file)
      data = YAML.load_file(file)
      data["exclude"] ||= []
      data["teams"].each{|team|
        team["members"] -= data["exclude"]
      }
      data["teams"].map{|d|
        Team.new(d["name"], Set.new(d["members"]))
      }
    end

    def member?(s)
      members.include?(s)
    end
  end

  class Scorer
    def score(teams, rooms, blocks)
      print UTF8BOM
      csv = CSV.new($stdout)
      csv << ["score", "conflicts"] + 1.upto(blocks).map{|i| "block#{i}" }

      split_number(teams.size, rooms, blocks).each{|rooms|
        fill_rooms(teams, rooms).each do |teams_in_rooms|
          score = 0
          conflicts = Set.new
          teams_in_rooms.each{|teams_in_room|
            teams_in_room.combination(2).each do |t1, t2|
              c = (t1.members & t2.members)
              c.each{|m| conflicts << m }
              # 被ってる延べ人数
              score -= c.size
            end
          }
          csv << [score, conflicts.to_a.join("、")] + teams_in_rooms.map{|teams| teams.map(&:name).join(" / ") }
        end
      }
    end

    private
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
  end
end

EnsembleScheduler::CLI.start(ARGV)

# A service that generates round-robin matches for a tournament.
class MatchGeneratorService
    include RRSchedule
    
  # Generate (and save Match objects for) matches for the given tournament.
  # If there are existing matches for the tournament, they will be deleted.
  # Return the matches if successful, otherwise nil. 
  def generate_for(tournament)
    return [] unless tournament.players.count > 1

    matches = []
    start_at = tournament.start_at

    tournament.transaction do
      tournament.matches.destroy_all
      
      schedule = RRSchedule::Schedule.new(
        #array of teams that will compete against each other. If you group teams into multiple flights (divisions),
        #a separate round-robin is generated in each of them but the "physical constraints" are shared
        :teams => tournament.players.to_a,
        #Setup some scheduling rules
        :rules => [
          RRSchedule::Rule.new(:wday => 3, :gt => ["7:00PM","9:00PM"], :ps => ["field #1", "field #2"]),
          RRSchedule::Rule.new(:wday => 5, :gt => ["7:00PM"], :ps => ["field #1"])
        ],
            
        #First games are played on...
        :start_date => start_at.to_date,
        
        #array of dates to exclude
        :exclude_dates => [Date.parse("2017/04/15"),Date.parse("2017/04/16")],
                          
        #Number of times each team must play against each other (default is 1)
        :cycles => 1,
         
        #Shuffle team order before each cycle. Default is true
        :shuffle => true
      ).generate
      
      schedule.gamedays.each do |gd|
        gd.games.each do |game|
          match = Match.new(
            tournament: tournament,
            home_player: game.team_a,
            away_player: game.team_b,
            start_at: game.game_time)

          match.save!
          matches << match
        end
      end

      # round_robin_pairings(tournament).values.each do |pair|
      #   match = Match.new(
      #     tournament: tournament,
      #     home_player: pair[:home_player],
      #     away_player: pair[:away_player],
      #     start_at: start_at)

      #   match.save!
      #   matches << match
      #   start_at += 3.hours # assume 3-hour match times for now
      # end
    end

    matches

  rescue ActiveRecord::RecordInvalid
    nil
  end

  private

  # Return a Hash of pairs representing the round-robin (each player plays all other players)
  # for the given tournament. Each pair is a hash containing two keys, :home_player and :away_player.
  def round_robin_pairings(tournament)
    pairs = {}
    players = tournament.players.to_a

    players.each do |player|
      other_players(player, players).each do |opponent|
        pairs[key_for(player, opponent)] ||= { home_player: player, away_player: opponent }
      end
    end

    pairs
  end

  def other_players(except_player, players)
    players - Array(except_player)
  end

  # Make a hash key to store the players in a pair. The key prevents the players from playing
  # each other more than once. The key is the player ids in order of lowest
  # to highest.
  def key_for(player1, player2)
    if player1.id < player2.id
      "#{player1.id}/#{player2.id}"
    else
      "#{player2.id}/#{player1.id}"
    end
  end
end

# A service that generates round-robin matches for a tournament.
class MatchGeneratorService
    include RRSchedule
    
  # Generate (and save Match objects for) matches for the given tournament.
  # If there are existing matches for the tournament, they will be deleted.
  # Return the matches if successful, otherwise nil. 
  def generate_for(tournament)
    return [] unless tournament.players.count > 1

    matches = []

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
        :start_date => tournament.start_at.to_date,
        
        #array of dates to exclude
        :exclude_dates => [],
                          
        #Number of times each team must play against each other (default is 1)
        :cycles => 1,
         
        #Shuffle team order before each cycle. Default is true
        :shuffle => true
      ).generate
      
      schedule.gamedays.each do |gd|
        gd.games.each do |g|
          if ![g.team_a,g.team_b].include?(:dummy)
            date = gd.date
            time = g.game_time
            match = Match.new(
              tournament: tournament,
              round: g.round,
              start_at: DateTime.new(date.year, date.month, date.day, time.hour, time.minute, 0, 0),
              home_player: g.team_a,
              away_player: g.team_b)
            match.save!
            matches << match
          end
        end
      end
    end

    matches

  rescue ActiveRecord::RecordInvalid
    nil
  end
end
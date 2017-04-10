require "rails_helper"

describe MatchGeneratorService do
  describe "#generate_for" do
    let(:tournament) { build_stubbed(:tournament) }
    let(:player1) { create(:user) }
    let(:player2) { create(:user) }
    let(:player3) { create(:user) }
    let(:player4) { create(:user) }
    let(:matches) { MatchGeneratorService.new.generate_for(tournament) }
    let(:p1_matches) { matches.select { |m| m.home_player == player1 || m.away_player == player1 }}
    let(:p2_matches) { matches.select { |m| m.home_player == player2 || m.away_player == player2 }}
    let(:p3_matches) { matches.select { |m| m.home_player == player3 || m.away_player == player3 }}

    context "no players" do
      before { expect_any_instance_of(Match).to_not receive(:save!) }

      it "returns an empty array" do
        expect(matches).to eq []
      end
    end

    context "1 player" do
      before do
        expect_any_instance_of(Match).to_not receive(:save!)
        allow(tournament).to receive(:players).and_return [player1]
      end

      it "returns an empty array" do
        expect(matches).to eq []
      end
    end

    context "2 players" do
      let(:players) { [player1, player2] }

      before do
        allow(tournament).to receive(:players).and_return players
        allow_any_instance_of(Match).to receive(:save!)
        expect(tournament).to receive_message_chain("matches.destroy_all")
      end

      it "creates 1 match" do
        expect(matches.count).to eq 1
      end
    end

    context "3 players" do
      before do
        allow(tournament).to receive(:players).and_return [player1, player2, player3]
        allow_any_instance_of(Match).to receive(:save!)
        expect(tournament).to receive_message_chain("matches.destroy_all")
      end

      it "creates 3 matches" do
        expect(matches.count).to eq 3
      end

      it "has match for player1 vs player2" do
        expect(p1_matches.select { |m| m.home_player == player2 || m.away_player == player2 }.count).to eq 1
      end

      it "has match for player1 vs player3" do
        expect(p1_matches.select { |m| m.home_player == player3 || m.away_player == player3 }.count).to eq 1
      end

      it "has match for player3 vs player2" do
        expect(p3_matches.select { |m| m.home_player == player2 || m.away_player == player2 }.count).to eq 1
      end
    end

    context "4 players" do
      before do
        allow(tournament).to receive(:players).and_return [player1, player2, player3, player4]
        allow_any_instance_of(Match).to receive(:save!)
        expect(tournament).to receive_message_chain("matches.destroy_all")
      end

      it "creates 6 matches" do
        expect(matches.count).to eq 6
      end

      it "has match for player1 vs player2" do
        expect(p1_matches.select { |m| m.home_player == player2 || m.away_player == player2 }.count).to eq 1
      end

      it "has match for player1 vs player3" do
        expect(p1_matches.select { |m| m.home_player == player3 || m.away_player == player3 }.count).to eq 1
      end

      it "has match for player1 vs player4" do
        expect(p1_matches.select { |m| m.home_player == player4 || m.away_player == player4 }.count).to eq 1
      end

      it "has match for player2 vs player3" do
        expect(p2_matches.select { |m| m.home_player == player3 || m.away_player == player3 }.count).to eq 1
      end

      it "has match for player2 vs player4" do
        expect(p2_matches.select { |m| m.home_player == player4 || m.away_player == player4 }.count).to eq 1
      end

      it "has match for player3 vs player4" do
        expect(p3_matches.select { |m| m.home_player == player4 || m.away_player == player4 }.count).to eq 1
      end
    end
  end
end

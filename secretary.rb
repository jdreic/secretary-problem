# frozen_string_literal: true

class Probability
  def secretary(n)
    r = (n / Math::E).ceil
    base = (r - 1.0)/n
    sum = (r..n).map do |i|
      1.0 / (i - 1.0)
    end.reduce(&:+)
    base * sum
  end
end

class Simulator
  def self.result(n)
    new(n).result
  end

  attr_reader :n

  def initialize(n)
    @n = n
  end

  def result
    [selection, win?]
  end

  private

  def selection
    @selection ||= candidates.drop(magic_number).find { |k| k < floor } || candidates.last
  end

  def win?
    selection == 1
  end

  def magic_number
    raise 'not implemented'
  end

  def candidates
    @candidates ||= (1..n).to_a.shuffle
  end

  def floor
    @floor ||= candidates.first(magic_number).min
  end
end

class ClassicSim < Simulator
  private

  def magic_number
    (n.to_f / Math::E).ceil
  end
end

class ValueSim < Simulator
  private

  def magic_number
    Math.sqrt(n).ceil
  end
end

class PostdocSim < Simulator
  private

  def selection
    @selection ||= candidates.drop(magic_number).reduce([subfloor, floor]) do |(sf, f), k|
      break(k) if k < sf && k > f
      break(k) if k == candidates.last
      next([f, k]) if k < f
      [sf, f]
    end
  end

  def subfloor
    @subfloor ||= candidates.first(magic_number).reject { |x| x == floor }.min
  end

  def magic_number
    (n.to_f / 2).floor
  end

  def win?
    selection == 2
  end
end

class Trial
  attr_reader :sim, :trial_count, :candidate_count

  def initialize(sim, trial_count, candidate_count)
    @sim = sim
    @trial_count = trial_count
    @candidate_count = candidate_count
  end

  def report
    puts '=' * 80
    puts report_str
    puts "won #{win_percentage * 100}% of the time"
    puts "average rank was #{average_rank}"
  end

  private

  def report_str
    case true
    when sim == ClassicSim
      "searching for best out of #{candidate_count} candidates, #{trial_count} times"
    when sim == ValueSim
      "when trying to get the best expected value of #{candidate_count} candidates, #{trial_count} times"
    when sim == PostdocSim
      "when trying to get the second best of #{candidate_count} candidates, #{trial_count} times"
    end
  end

  def results
    @results ||= trial_count.times.map { |x| sim.result(candidate_count) }
  end

  def average_rank
    @values ||= (results.map(&:first).reduce(&:+).to_f / trial_count).round(0)
  end

  def win_percentage
    @win_percentage ||= (results.map { |a| a[1] }.count(&:itself).to_f / trial_count).round(4)
  end
end

Trial.new(ClassicSim, 500, 100).report
Trial.new(ClassicSim, 500, 1000).report
Trial.new(ClassicSim, 500, 1_000_000).report

Trial.new(ValueSim, 500, 100).report
Trial.new(ValueSim, 500, 1000).report
Trial.new(ValueSim, 500, 1_000_000).report

Trial.new(PostdocSim, 500, 100).report
Trial.new(PostdocSim, 500, 1000).report
Trial.new(PostdocSim, 500, 1_000_000).report

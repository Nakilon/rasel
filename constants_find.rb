require_relative "lib/rasel"
require "set"
require "pcbr"
require "timeout"
require "pp"
pcbr = PCBR.new
best = []
seen = []
loop do
  puts ""
  unseen = (pcbr.table.sort_by(&:last).map(&:first) - seen)
  base = unseen.first || ""
  p [seen.size, unseen.size, base, pcbr.table.size]
  seen.push base
  pp( best.sort.group_by(&:first).flat_map do |n, g|
    shortest = g.map(&:last).map(&:size).min
    g.map{ |n, code| [n, code, [code.size, code.delete("^0-9A-Z").chars.max || "0"]] if code.size == shortest }.
      compact.sort_by(&:last)
  end )
  sorted = pcbr.table.reject do |_,|
    %w{
      0 1 Z 0: 01 10 1: 01- 0Z- 01\\ 1:\\ 1Z- 1Z/ Z1\\ 01-0 01-1 01-: 01\\-
      01-01- 01-1\\ 01\\-0 01\\-1 01\\-: 101-- 01-Z- 01-Z/ 0Z-1- 0Z-1\\ 0Z-Z- 1Z-1\\ 1Z-Z- 1Z-Z/ 01Z/- 10Z-/ 1:Z-/ 1Z/Z/
      1Z/1- 1Z/1\\ 1Z/Z-
    }.include? _
  end.sort_by{ |_| [_.last, _.first] }
  pp sorted[0,10]
  pp sorted[-10..-1]
# %w{ 0 1 Z # : j ? - % / \\ }.each do |c|
  %w{ 0 1 Z   :     - % / \\ }.each do |c|
    code = base + c
    next unless %w{ 0 1 Z }.include? code[0]
    # next unless %w{ 0 1 Z # }.include? code[0]

    # next if %w{ 0j ## }.include? code[-2,2]
    next if code[/0:*[-?\\\/%]\z/]
    next if code[/[01Z](:|[01Z]-)*[1Z]%\z/]
    next if code[/[01Z](:|[01Z]-)*[01Z]1\\\z/]
    next if %w{ :% :- 1/ 00 11 ZZ }.include? code[-2,2]
    next if %w{ 0Z/ 1:/ Z:/ :1\\ Z1- }.include? code[-3,3]
    next if %w{ 01-\\ 0Z-\\ 1Z-\\ 01\\/ 01\\% 1::\\ 01:\\ 1::/ Z::/ Z:Z/ 1:1- Z:Z- 1\\1\\ 0:Z/ 1-1- Z:1- Z1:\\ }.include? code[-4,4]
    next if %w{ 0:1-% 101-% 01Z-% 01Z/% 0:Z-% 1:Z-% Z1Z-% 10Z-% 1:Z/% 1Z/1% 1Z/Z% 01-:/ 01-:\\ 0:1-/ 101-/ 0:1-- 0:1-\\ 0Z-:/ 0Z-:\\ 0Z-Z/ 1Z-:/ 1Z-:\\ 01Z-- 01Z-/ 01Z// 0:Z-/ 0:Z-- 10Z-- 1:Z-- 0:Z-\\ 1:Z-\\ 1:Z/- 1:Z// 1Z/:/ Z1Z/- Z01-% 1:\\1\\ Z1Z/% 1Z-1- Z0Z-% Z0Z-/ Z01-/ }.include? code[-5,5]
    next if %w{ }.include? code[-6,6]
    next if %w{ Z1Z//Z/ }.include? code[-7,7]

    next if code.start_with? "1\\"
    # next if %w{ 1\\ 1- 1% Z% Z- Z/ }.include? code[0,2]
    # next if %w{ 01-% 0Z-% 01-/ 0Z-/ 01-- 0Z-- 1:\\- Z1\\- 1:\\/ Z1\\/ 1:\\% Z1\\% 01\\\\ 1:\\\\ Z1\\\\ 01\\- 1Z-% 1Z-- 1Z-/ 1Z/% 1Z/- 1Z// }.include? code[0,4]
    # next if %w{ 1:\\:/ 01\\1% 01\\1- 01\\Z% 01\\Z- 01\\Z/ 01\\:/ 1:\\1% 1:\\1- 01\\:\\ 1:\\:\\ Z1\\Z- Z1\\Z% 1:\\Z% 1:\\Z- 1:\\Z/ 1Z-1- Z1\\Z/ Z1\\:\\ Z1\\1% Z1\\1- Z1\\:/ }.include? code[0,5]
    # next if %w{ }.include? code[0,6]

    begin
      result = Timeout.timeout(0.1){ RASEL("Z-Z-" + code + " 0@") }
    rescue Timeout::Error
      next
    end
    next unless result.exitcode.zero?
    next unless result.stack.first == -70
    pcbr.store code, [(result.stack.size - 2).abs, base.size]
    best.push [result.stack[1].to_i, code] if result.stack.size == 2 && result.stack[1] > 0 && result.stack[1].denominator == 1
  end
end

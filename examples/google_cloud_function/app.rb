require "functions_framework"
FunctionsFramework.http do |request|
  require "json"
  input = JSON.load request.body.read   # JSON.load makes .encoding="utf-8"
  break "invalid command syntax" unless ((
    split = ->(a,b){ s,i,r=0,0,[]; until i==a.size do (r.push a[s...i] ; s=i+b.size) if i>=s && a[i,b.size]==b ; i+=1 end ; r+[a[s..-1]] }
    code, stdin = case input
    when /\A-stdin(.)(.+?)\1-multiline(.)(.+)\z/ ; [split[$4, $3].join("\n"), $2]
    when /\A-stdin(.)(.+?)\1(.+)\z/              ; [$3, $2]
    when /\A-multiline(.)(.+)\z/                 ; [split[$2, $1].join("\n")]
    else input
    end
  ))
  require "rasel"
  result = if stdin
    begin
      RASEL code, StringIO.new, StringIO.new.tap{ |_| stdin.encode("ascii").bytes.reverse_each &_.method(:ungetbyte) }
    rescue Encoding::UndefinedConversionError
      break "invalid stdin encoding"
    end
  else
    RASEL code
  end
  # we consciously sacrifice the exit code info in order to see more output
  "output: #{result.stdout.string[0,600]}, exit code: #{result.exitcode}"
end

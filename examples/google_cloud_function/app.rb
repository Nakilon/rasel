require "functions_framework"
FunctionsFramework.http do |request|
  input = Base64::strict_decode64(request.body.read).force_encoding "utf-8"
  # we ensure that we accepted utf-8 just because this function is for IRC in the first place
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

# $ rbenv local 2.6.6   # because that's the ruby version image provided by GCF
# $ bundle exec functions-framework-ruby
# $ curl -X POST -d $(printf '"!dlroW ,olleH">:?@,Gj' | base64) http://localhost:8080
# $ curl -X POST -d $(printf %s '-stdin 1 \& .@' | base64) http://localhost:8080
# $ curl -X POST -d $(printf %s '-multiline| v >@| >2^' | base64) http://localhost:8080
# $ curl -X POST -d $(printf %s '-stdin|2|-multiline|& v >.@|  >3v' | base64) http://localhost:8080
# $ gcloud functions deploy ... --entry-point function --runtime ruby26 --trigger-http --timeout=30s --memory=128MB --max-instances 5
# this doesn't work since we switched from JSON to BASE64 in the outer layer $ gcloud functions call ... --data '"\"!dlroW ,olleH\">:?@,Gj"'
# $ curl -X POST -d $(printf %s '-stdin|2|-multiline|& v >.@|  >3v' | base64) https://...cloudfunctions.net/... -H "Authorization: bearer $(gcloud auth print-identity-token)"
# $ curl -X POST -d $(printf %s '-stdin|2|-multiline|& v >.@|  >3v' | base64) https://...cloudfunctions.net/... -H "Authorization: bearer $(gcloud auth print-identity-token <GCLOUD ACTIVATED (not active) SERVICE ACCOUNT EMAIL>)"

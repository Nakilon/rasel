require "functions_framework"
FunctionsFramework.http do |request|
  input = JSON.parse request.body.read.force_encoding "utf-8"
  # TODO: not sure why I change the request's ASCII to UTF-8 that RASEL does not support anyway...
  require "rasel"
  result = if /\A-stdin (.)(.+?)\1(.+)\z/ =~ input
    RASEL $3, StringIO.new, StringIO.new.tap{ |_| $2.encode("ascii").bytes.reverse_each &_.method(:ungetbyte) }
  else
    RASEL input
  end
  "output: #{result.stdout.string[0,500].inspect}, exit code: #{result.exitcode}"
end

# $ bundle exec functions-framework-ruby
# $ curl -X POST -d '"\"!dlroW ,olleH\">:?@,Gj"' http://localhost:8080
# $ gcloud functions deploy ... --entry-point function --runtime ruby26 --trigger-http --timeout=30s --memory=128MB --max-instances 5
# $ gcloud functions call ... --data '"\"!dlroW ,olleH\">:?@,Gj"'
# $ curl -X POST -d '"\"!dlroW ,olleH\">:?@,Gj"' https://...cloudfunctions.net/... -H "Authorization: bearer $(gcloud auth print-identity-token)"
# $ curl -X POST -d '"\"!dlroW ,olleH\">:?@,Gj"' https://...cloudfunctions.net/... -H "Authorization: bearer $(gcloud auth print-identity-token <GCLOUD ACTIVATED (not active) SERVICE ACCOUNT EMAIL>)"

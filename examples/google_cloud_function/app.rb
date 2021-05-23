require "functions_framework"
FunctionsFramework.http do |request|
  require "rasel"
  result = RASEL JSON.parse request.body.read.force_encoding "utf-8"
  "output: #{result.stdout.string.inspect}, exit code: #{result.exitcode}"
end

# $ bundle exec functions-framework-ruby
# $ curl -X POST -d '"\"!dlroW ,olleH\">:?@,Gj"' http://localhost:8080
# $ gcloud functions deploy ... --entry-point function --runtime ruby26 --trigger-http --timeout=5s --memory=128MB --max-instances 1
# $ gcloud functions call ... --data '"\"!dlroW ,olleH\">:?@,Gj"'
# $ curl -X POST -d '"\"!dlroW ,olleH\">:?@,Gj"' https://...cloudfunctions.net/... -H "Authorization: bearer $(gcloud auth print-identity-token)"
# $ curl -X POST -d '"\"!dlroW ,olleH\">:?@,Gj"' https://...cloudfunctions.net/... -H "Authorization: bearer $(gcloud auth print-identity-token <GCLOUD ACTIVATED (not active) SERVICE ACCOUNT EMAIL>)"

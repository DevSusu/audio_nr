require 'sinatra'

get '/' do
 'hello world!'
end

post '/records' do
  p params
  File.open('records/' + params['file'][:filename], "w") do |f|
    f.write(params['file'][:tempfile].read)
  end
  "The file was successfully uploaded!"
end
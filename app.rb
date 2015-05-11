require 'sinatra'

preffered_content_types = ['audio/wav' , 'application/octet-stream']

get '/' do
 'hello world!'
end

post '/records' do
  p params

  if not preffered_content_types.include? params['file'][:type]
    status 415 # Unsupported Media Type
    return "Unsupported Media Type. Only support #{preffered_content_types}"
  end

  File.open('records/' + params['file'][:filename], "w") do |f|
    f.write(params['file'][:tempfile].read)
  end
  "The file was successfully uploaded!"
end
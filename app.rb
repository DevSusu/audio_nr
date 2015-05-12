require 'sinatra'
# require 'dotenv'
# Dotenv.load

preffered_content_types = ['application/octet-stream' , 'audio/ogg']
DURATION_REGEX = /Duration:([0-9:.]+)/
FILENAME_REGEX = /[\w]+_nr.ogg/

# use Rack::Auth::Basic, "Protected Area" do |username, password|
#   username == ENV['username'] && password == ENV['password']
# end

get '/' do
 'hello world!'
end

get '/records' do
  filename = params['file']
  p filename

  if filename =~ FILENAME_REGEX
    send_file filename, :type => 'audio/ogg'
  else
    status 400
    'Bad file name'
  end

end

post '/records' do
  p params

  filename = params['file'][:filename]
  type = params['file'][:type]

  if not preffered_content_types.include? type
    status 415 # Unsupported Media Type
    return "Unsupported Media Type. Only support #{preffered_content_types}"
  end

  File.open('records/' + filename, "w") do |f|
    f.write(params['file'][:tempfile].read)
  end

  noise_profile(filename)
  
  "The file was successfully uploaded and noise reducted!"
end

def noise_profile(filename)
  # Run command soxi to collect file header. For example,
  # Input File     : 'filename.wav'
  # Channels       : 1
  # Sample Rate    : 44100
  # Precision      : 16-bit
  # Duration       : 00:00:39.50 = 1741824 samples = 2962.29 CDDA sectors
  # File Size      : 3.48M
  # Bit Rate       : 706k
  # Sample Encoding: 16-bit Signed Integer PCM
  header = `soxi records/#{filename}`
  header = header.gsub(' ','') # removing whitespaces

  # convert = `sox records/#{filename} records/#{filename.split('.')[0]}.wa`

  duration = header.match(DURATION_REGEX).to_s.split(':')[1..-1].map{ |s| s.to_f }
  duration_sec = duration[-1] + duration[-2]*60 + duration[-3] * 3600
  p duration_sec

  # sox noisey_voice.wav -n trim 7 7.25 noiseprof speech.noise-profile
  # currently trimming end of audio file for noise profiling
  profile = `sox records/#{filename} -n trim #{0} #{duration_sec-1} noiseprof records/#{filename}.noise-profile`
  p profile

  # noise reduction based on noise profile above
  noise_red_alpha = 0.2
  noise_red = `sox records/#{filename} #{filename.split('.')[0]}_nr.wav noisered records/#{filename}.noise-profile #{noise_red_alpha}`
  p noise_red

end
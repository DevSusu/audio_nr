require 'sinatra'
require 'fog'
require 'dotenv'
Dotenv.load
set :port, 80

preffered_content_types = ['application/octet-stream' , 'audio/ogg']

URL_REGEX = /https:\/\/loroclip-staging\.s3\.amazonaws\.com\/uploads\/(?<uuid>[\w-]+)\.ogg/

get '/' do
 'hello world!'
end

get '/nr' do
  ts = Time.now

  if params['uuid'].nil? or params['url'].nil?
    return 'Parameter uuid is missing'
  end

  url = params['url']
  uuid = params['uuid']

  if not url.nil? and url =~ URL_REGEX

    file = URL_REGEX.match(url)['uuid']

    pid = fork do
      # Download recording from s3
      `curl -o #{file}.ogg #{url}`
      # NR on white noise
      `sox #{file}.ogg #{file}-nr.ogg noisered noise_white.noise-profile 0.2`
      # Clean up
      `rm #{file}.ogg`

      # Upload NR file
      if upload(file+'-nr.ogg')
        # upload successful
        # Send API request to inform server
        reducted(file,uuid)
      end

      `rm #{file}-nr.ogg`
    end

    'https://loroclip-staging.s3.amazonaws.com/uploads/%s-nr.ogg' % file

  else
    'URL is not in an appropriate format or missing'
  end

end

def reducted(file,uuid)
  # Create a request on rails server
  # find record with uuid
  # change record's status to Reducted
  uri = URI.parse(ENV['NR_API'])
  params = {
    :url => "https://loroclip-staging.s3.amazonaws.com/uploads/#{file}-nr.ogg",
    :uuid => uuid,
  }
  res = Net::HTTP.post_form(uri, params)

end

def upload(filename)

  connection = Fog::Storage.new({
    :provider               => 'AWS',
    :aws_access_key_id      => ENV['AWS_ACCESS_KEY_ID'],
    :aws_secret_access_key  => ENV['AWS_SECRET_ACCESS_KEY'],
  })

  directory = connection.directories.get(ENV['AWS_BUCKET_NAME']);

  file = directory.files.new({
    :key                    => 'uploads/' + filename,
    :body                   => File.open(filename),
    :public                 => true,
    })

  file.save

end


require 'sinatra'
require 'byebug'
require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'base64'

post('/krafty') do
  req_body = JSON.parse(request.body.read)
  response_code = req_body['Body']['stkCallback']['ResultCode']
  if response_code.to_i.zero?
    'You have paid. Give us three days'
  else
    puts 'mbuzi wewe'
    erb :index
  end
end

get '/' do
  erb :index
end

post '/' do
  phone_number = params[:phone]
  amount = params[:amount]
  business_short_code = 174_379
  timestamp = Time.now.strftime('%Y%m%d%H%M%S')
  passkey = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919'
  request_body = "{
  \"BusinessShortCode\": \"#{business_short_code}\",
  \"Password\": \"#{password(business_short_code, timestamp, passkey)}\",
  \"Timestamp\": \"#{timestamp}\",
  \"TransactionType\": \"CustomerPayBillOnline\",
  \"Amount\": \"#{amount}\",
  \"PartyA\": \"#{phone_number}\",
  \"PartyB\": \"#{business_short_code}\",
  \"PhoneNumber\": \"#{phone_number}\",
  \"CallBackURL\": \"https://9edd5946.ngrok.io/krafty\",
  \"AccountReference\": \"account\",
  \"TransactionDesc\": \"Paying for shoes\"
}"
  uri = URI('https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Post.new(uri)
  request['accept'] = 'application/json'
  request['content-type'] = 'application/json'
  request['authorization'] = "Bearer #{access_token}"
  request.body = request_body
  res = http.request(request)
  p res.read_body
  'Payment being processed'
end

def password(business_short_code, timestamp, passkey)
  Base64.strict_encode64(business_short_code.to_s + passkey + timestamp)
end

def access_token
  uri = URI('https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(uri)
  request['accept'] = 'application/json'
  request['content-type'] = 'application/json'
  request.basic_auth 'LBPIC4sAqMIdeTxSd8CPA2TIENtWnbn8', 'zMp2zUqa7ME5OhAV'
  res = JSON.parse http.request(request).body
  res['access_token']
end

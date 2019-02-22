class HttpService
  require 'base64'
  require 'net/http'
  require 'net/https'
  require 'uri'

  @@http_testing = Rails.env.development? ? true : false
  # ============================================================================
  # Requests ===================================================================
  # ============================================================================
  def get(path, options = { body: nil, content_type: nil, headers: nil })
    HttpService.get(path, options)
  end

  def post(path, options = { body: nil, content_type: nil, headers: nil })
    HttpService.post(path, options)
  end

  def patch(path, options = { body: nil, content_type: nil, headers: nil })
    HttpService.patch(path, options)
  end

  # ============================================================================
  # Formatting =================================================================
  # ============================================================================
  def encode64(string)
    HttpService.encode64(string)
  end

  def format_hmac(options = { data: nil, digest: nil, key: nil })
    HttpService.format_hmac(options)
  end
  

  private
  # ============================================================================
  # Requests ===================================================================
  # ============================================================================
  def self.get(path, options = { body: nil, content_type: nil, headers: nil })
    request_params = HttpService.build_get_request(path, options)
    http           = request_params[:http]
    request        = request_params[:request]

    HttpService.puts_request(request) if options[:puts_request].present? || @@http_testing == true

    response = http.request(request)

    HttpService.puts_response(response) if options[:puts_response].present? || @@http_testing == true

    options[:process_response] ? process_response(response) : response
  end

  def self.post(path, options = { body: nil, content_type: nil, headers: nil })
    request_params = HttpService.build_post_request(path, options)
    http           = request_params[:http]
    request        = request_params[:request]

    HttpService.puts_request(request) if options[:puts_request].present? || @@http_testing == true

    response = http.request(request)

    HttpService.puts_response(response) if options[:puts_response].present? || @@http_testing == true

    options[:process_response] ? process_response(response) : response
  end

  def self.patch(path, options = { body: nil, content_type: nil, headers: nil })
    request_params = HttpService.build_patch_request(path, options)
    http           = request_params[:http]
    request        = request_params[:request]

    HttpService.puts_request(request) if options[:puts_request].present? || @@http_testing == true

    response = http.request(request)

    HttpService.puts_response(response) if options[:puts_response].present? || @@http_testing == true

    options[:process_response] ? process_response(response) : response
  end

  # ============================================================================
  # Builders ===================================================================
  # ============================================================================
  def self.build_get_request(path, options = {  })
    uri     = URI(path)
    http    = HttpService.format_ssl(uri)
    request = Net::HTTP::Get.new(uri)

    request = HttpService.build_headers(request, options[:headers])
    request = HttpService.build_content_type(request, options[:content_type])

    request.body = options[:body] if options[:body].present?

    return { http: http, request: request }
  end

  def self.build_post_request(path, options = {  })
    uri     = URI(path)
    http    = HttpService.format_ssl(uri)
    request = Net::HTTP::Post.new(uri)

    request = HttpService.build_headers(request, options[:headers])
    request = HttpService.build_content_type(request, options[:content_type])

    request.body = options[:body] if options[:body].present?

    return { http: http, request: request }
  end

  def self.build_patch_request(path, options = {  })
    uri     = URI(path)
    http    = HttpService.format_ssl(uri)
    request = Net::HTTP::Patch.new(uri)

    request = HttpService.build_headers(request, options[:headers])
    request = HttpService.build_content_type(request, options[:content_type])

    request.body = options[:body] if options[:body].present?

    return { http: http, request: request }
  end

  def self.build_headers(request, headers = {  })
    return request if headers.nil? || headers.empty?
    headers.each do |k, v|
      request[k] = v
    end

    return request
  end

  def self.build_content_type(request, content_type)
    if content_type.present?
      request["Content-Type"] = content_type
    end

    return request
  end

  # ============================================================================
  # Formatting =================================================================
  # ============================================================================
  def self.encode64(string)
    Base64.strict_encode64(string)
  end

  def self.format_ssl(uri)
    http             = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl     = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    return http
  end

  def self.format_hmac(options = { data: nil, digest: nil, key: nil })
    return if options[:key].blank? && options[:data].blank?
    digest = options[:digest].present? ? options[:digest] : OpenSSL::Digest.new('sha256')
    OpenSSL::HMAC.hexdigest(digest, options[:key], options[:data])
  end

  def self.percent_of(a, b)
    a.to_f / b.to_f * 100.0
  end

  def self.process_response(response)
    return response if response.blank?

    begin
      HashWithIndifferentAccess.new(JSON.parse(response.read_body))
    rescue => error
      puts nil, "An error has occured", nil
      puts error.message.first(200)
      return {}
    end
  end

  # ============================================================================
  # Troubleshooting ============================================================
  # ============================================================================
  def self.puts_request(request)
    puts "=" * 89, "REQUEST TO #{request.uri}", "=" * 89

    print "REQUEST (#{request.class}): "
    puts HttpService.paint(request)
    print "PATH (#{request.path.class}): "
    puts HttpService.paint(request.path)
    print "HEADERS (#{request['headers'].class}): "
    puts HttpService.paint(request[:headers])

    ["Authorization", "Content-Type", "On-Behalf-Of", "x-smarttoken"].each do |header|
      if request[header].present?
        print " " * 5, "#{header} (#{request[header].class}): "
        puts HttpService.paint(request[header])
      end
    end

    print "BODY (#{request.body.class}): "
    puts HttpService.paint(request.body)
    puts nil, nil, nil
    puts "=" * 89 unless @@http_testing == true
  end

  def self.puts_response(response)
    puts "=" * 89, "CODE #{response.code} | URI #{response.uri} | HTTP V. #{response.http_version}", "=" * 89
    print "REQUEST (#{response.class}): "
    puts HttpService.paint(response.message)
    print "HEADERS (#{response.header.class}): "
    puts HttpService.paint(response.header)

    [:content_type, :content_length, :error_type].each do |e|
      if response.header.send(e).present?
        print " " * 5, "#{e.to_s} (#{response.header.send(e).class}): "
        puts HttpService.paint(response.header.send(e))
      end
    end

    print "BODY (#{response.body.class}): "
    puts HttpService.paint(response.body.first(500))
    puts nil, nil, nil
    puts "=" * 89

  end

  def self.paint(v)
    case v.class.to_s
    when "ActiveSupport::TimeWithZone", "Date", "Time", "DateTime"
      "\e[#{32}m#{v}\e[0m"
    when "Fixnum"
      "\e[#{34}m#{v}\e[0m"
    when "NilClass"
      "\e[#{31}m#{'nil'}\e[0m"
    when "String"
      "\e[#{33}m#{v}\e[0m"
    when "FalseClass", "TrueClass"
      "\e[#{32}m#{v}\e[0m"
    else
      "\e[#{35}m#{v}\e[0m"
    end
  end
end

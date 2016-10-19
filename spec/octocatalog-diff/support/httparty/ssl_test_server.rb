# Adapted from https://github.com/jnunemaker/httparty/tree/master/spec/support

require 'openssl'
require 'socket'
require 'tempfile'
require 'thread'

class SSLTestServer
  attr_reader :port

  def initialize(options = {})
    @options   = options
    @port      = 0
    @child_pid = nil
  end

  def start
    file = ::Tempfile.new('ssl-port-num.txt')
    file.close
    @child_pid = fork { SSLTestServer.thread_main(file.path, @options) }
    3.times do
      @port = File.read(file.path).to_i
      break if @port > 0
      sleep 0.1
    end
    stop unless @port > 0
  ensure
    FileUtils.rm file.path
  end

  def stop
    if @child_pid.is_a?(Fixnum)
      begin
        Process.kill('TERM', @child_pid)
        Process.wait
      rescue Errno::ESRCH
        # If we get #<Errno::ESRCH: No such process>, then there is nothing
        # that needs to be stopped. We don't have to fail the test if this occurs.
      end
    end
  end

  def self.thread_main(tmpfile, options)
    ctx             = OpenSSL::SSL::SSLContext.new
    ctx.cert        = OpenSSL::X509::Certificate.new(options[:cert])
    ctx.key         = OpenSSL::PKey::RSA.new(options[:rsa_key])
    ctx.verify_mode = if options[:client_verify]
      OpenSSL::SSL::VERIFY_PEER | OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
    else
      OpenSSL::SSL::VERIFY_NONE
    end
    ctx.ca_file = options[:ca_file] if options[:ca_file]

    url_map = options[:url_map] || { '/foo' => '{"success":true}' }

    raw_server = TCPServer.new(0)
    port = Socket.getnameinfo(raw_server.getsockname, Socket::NI_NUMERICHOST | Socket::NI_NUMERICSERV)[1].to_i
    ssl_server = OpenSSL::SSL::SSLServer.new(raw_server, ctx)

    File.open(tmpfile, 'w') { |f| f.write(port) }

    10.times do
      begin
        socket = ssl_server.accept
      rescue OpenSSL::SSL::SSLError, Errno::ECONNRESET
        # This occurs during certain integration tests that fail to authenticate. Catch this error
        # to avoid printing stack traces that are expected.
        next
      end

      header = []
      body = ''
      begin
        until (line = socket.readline).rstrip.empty?
          header << line.strip
        end
        if header.first =~ /^POST/
          if (cl = header.select { |x| x =~ /^Content-Length: (\d+)/i }).any?
            cl.first =~ /^Content-Length: (\d+)/i
            body = socket.read(Regexp.last_match(1).to_i)
          end
        end
      rescue EOFError
        # do nothing
      end

      missing_header_error = nil
      if options[:require_header]
        options[:require_header].each do |k, v|
          next if header.include?("#{k}: #{v}")
          missing_header_error = k
        end
      end

      response = if missing_header_error
        <<EOF
HTTP/1.1 403 Forbidden
Connection: close
Content-Type: application/json; charset=UTF-8

{"error":"an expected header was not found"}
EOF
      elsif header.first =~ /GET (\S+)/
        if options[:handler]
          options[:handler].send(:response, :get, Regexp.last_match(1), header)
        elsif url_map.key?(Regexp.last_match(1))
          <<EOF
HTTP/1.1 200 OK
Connection: close
Content-Type: application/json; charset=UTF-8

#{url_map[Regexp.last_match(1)]}
EOF
        else
          <<EOF
HTTP/1.1 404 Not Found
Connection: close
Content-Type: application/json; charset=UTF-8

{"error":"not found"}
EOF
        end
      elsif options[:handler] && header.first =~ /POST (\S+)/
        options[:handler].send(:response, :post, Regexp.last_match(1), header, body)
      else
        <<EOF
HTTP/1.1 400 Bad Request
Connection: close
Content-Type: application/json; charset=UTF-8

{"error":"bad request"}
EOF
      end

      socket.write(response.gsub(/\r\n/n, "\n").gsub(/\n/n, "\r\n"))
      socket.close
    end
    ssl_server.close
    exit 0
  end
end

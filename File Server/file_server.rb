require './file_service.rb'
require '../utils.rb'
require './router.rb'
require './session.rb'

pool = ThreadPool.new(10)
file_service = FileService.new Digest::SHA1.hexdigest '__Thor__password__'
server = TCPServer.new(
  SERVICE_CONNECTION_DETAILS['file']['ip'],
  SERVICE_CONNECTION_DETAILS['file']['port'])

LOGGER.log 'Starting File Server'
LOGGER.log "Listening on #{SERVICE_CONNECTION_DETAILS['file']['ip']}:#{SERVICE_CONNECTION_DETAILS['file']['port']}"

loop do
  pool.schedule do
    begin
      user_socket = server.accept_nonblock
      session = Session.new user_socket, file_service

      LOGGER.log '//////////// Accepted connection ////////////////'

      while session.is_connected
        begin
          request = session.get_request()
          if request == ''
            LOGGER.log 'Empty request received. Disconnecting user.'
            session.disconnect()
          else
            begin
              Router.route(file_service, request, session)
            rescue => e
              LOGGER.log e
              LOGGER.log e.backtrace.join "\n"
            end
          end

        rescue
         # Dont starve the other threads you dick...
         sleep(2)
        end
      end

      LOGGER.log 'Connection to client has been lost'
      session.disconnect()

    rescue
      # DO NOTHING
    end
  end
end

at_exit { pool.shutdown }

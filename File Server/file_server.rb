require_relative './file_service.rb'
require_relative '../common/utils.rb'
require_relative './file_service_router.rb'

class FileServer

  def initialize server_details={}, key
    name = server_details['name']
    ip = server_details['ip']
    port = server_details['port']

    pool = ThreadPool.new(10)
    service = FileService.new name, key
    server = TCPServer.new(ip,port)

    LOGGER.log "\n ###############\n Starting File Server #{name} \n ###############"
    LOGGER.log "Listening on #{ip}:#{port}"

    loop do
      pool.schedule do
        begin
          user_socket = server.accept_nonblock
          session = ServiceSession.new user_socket, service

          LOGGER.log '//////////// File Server: Accepted connection ////////////////'

          while session.is_connected
            begin
              request = session.get_request()
              if request == ''
                LOGGER.log 'Empty request received. Disconnecting user.'
                session.disconnect()
              else
                begin
                  FileServiceRouter.route(service, request, session)
                rescue => e
                  LOGGER.log e
                  LOGGER.log e.backtrace.join "\n"
                end
              end

            rescue
             # Dont starve the other threads you dick...
             sleep(0.1)
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
  end

end

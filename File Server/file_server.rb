require_relative './file_service.rb'
require_relative '../common/utils.rb'
require_relative './file_service_router.rb'

class FileServer

  def initialize server_details={}, key
    name = server_details['name']
    ip = server_details['ip']
    port = server_details['port']

    service = FileService.new name, key
    server = TCPServer.new(ip,port)

    LOGGER.log "\n ###############\n Starting File Server #{name} \n ###############"
    LOGGER.log "Listening on #{ip}:#{port}"

    loop do
      Thread.start(server.accept) do |user_socket|
        begin
          session = ServiceSession.new user_socket, service
          LOGGER.log '//////////// File Server: Accepted connection ////////////////'
          loop do
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
          end
        rescue => e
          LOGGER.log e
        end
      end
    end
  end

end

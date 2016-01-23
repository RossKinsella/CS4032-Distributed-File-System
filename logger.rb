class Logger

  def initialize
    @enabled = true
    @thread_ids = {}
    @iterator = 0
  end

  def log message
    if @enabled
      if @thread_ids.include? Thread.current.object_id
        current = @thread_ids[Thread.current.object_id]
      else
        current = @iterator
        @thread_ids[Thread.current.object_id] = current
        @iterator = @iterator.next
      end
      puts "#{current}: #{message}"
    end
  end

end
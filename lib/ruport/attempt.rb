require 'timeout'

class Attempt
   VERSION = '0.1.0'
   
   # Number of attempts to make before failing.  The default is 3.
   attr_accessor :tries
   
   # Number of seconds to wait between attempts.  The default is 60.
   attr_accessor :interval
   
   # a level which ruport understands.  
   attr_accessor :log_level
   
   # If set, this increments the interval with each failed attempt by that
   # number of seconds.
   attr_accessor :increment
   
   # If set, the code block is further wrapped in a timeout block.
   attr_accessor :timeout
   
   # Determines which exception level to check when looking for errors to
   # retry.  The default is 'Exception' (i.e. all errors).
   attr_accessor :level
   
   # :call-seq:
   #    Attempt.new{ |a| ... }
   # 
   # Creates and returns a new +Attempt+ object.  Use a block to set the
   # accessors.
   # 
   def initialize           
      @tries     = 3         # Reasonable default
      @interval  = 60        # Reasonable default
      @increment = nil       # Should be an int, if provided
      @timeout   = nil       # Wrap the code in a timeout block if provided
      @level     = Exception # Level of exception to be caught
      
      yield self if block_given?
   end
   
   def attempt
      count = 1
      begin
         if @timeout
            Timeout.timeout(@timeout){ yield }
         else
            yield
         end
      rescue @level => error
         @tries -= 1
         if @tries > 0
            msg = "Error on attempt # #{count}: #{error}; retrying"
            count += 1
            Ruport.log(msg, :level => log_level)
            @interval += @increment if @increment
            sleep @interval
            retry
         end
         raise
      end
   end
end

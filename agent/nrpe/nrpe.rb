module MCollective
    module Agent
        class Nrpe<RPC::Agent
            def runcommand_action
                validate :command, String
               
                command = plugin_for_command(request[:command])

                reply.fail "No such command: #{request[:command]}" if command == nil
                return unless reply.statuscode == 0

                reply[:output] = %x[#{command[:cmd]}]
                reply[:exitcode] = $?.exitstatus

                case reply[:exitcode]
                    when 0
                        reply.statusmsg = "OK"

                    when 1
                        reply.fail "WARNING"

                    when 2
                        reply.fail "CRITICAL"

                    else
                        reply.fail "UNKNOWN"

                end

                if reply[:output] =~ /^(.+)\|(.+)$/
                    reply[:output] = $1
                    reply[:perfdata] = $2
                else
                    reply[:perfdata] = ""
                end
            end

            def help
                <<-EOH
                Simple RPC NRPE Agent
                =====================

                Agent that looks for defined commands in /etc/nagios/nrpe.d and runs the command.

                INPUT:
                    :command        The NRPE command to run

                OUTPUT:
                     :output        The string that the plugin gave
                     :exitcode      The exitcode from the plugin
                     :status        an OK, WARNING, CRITICAL or UNKNOWN string
                     :perfdata      any perfdata from the plugin
                EOH
            end

            private
            def plugin_for_command(req)
                ret = nil
    
                fname = "/etc/nagios/nrpe.d/#{req}.cfg"
    
                if File.exist?(fname)
                    t = File.readlines(fname).first.chomp
    
                    if t =~ /command\[.+\]=(.+)$/
                        ret = {:cmd => $1}
                    end
                end
    
                ret
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai

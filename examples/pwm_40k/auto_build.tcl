if {[catch {
    project open PWM_40k.xise
    process run "Generate Programming File" -force rerun_all
    project close
} message]} {
    puts stderr "BUILD ERROR: $message"
    catch {project close}
    exit 1
}
if {![file exists pwm_40k.bit]} {
    puts stderr "BUILD ERROR: pwm_40k.bit not found"
    exit 1
}
puts "BUILD COMPLETE: pwm_40k.bit"
exit 0


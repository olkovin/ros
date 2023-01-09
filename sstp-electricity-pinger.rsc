# electricity down detector
# based on sstp client and Mikrotik ROS

:global ChecksFailedCount
:global PingerIsRunning
:global ElectricityUpTime
:global ElectricityUpTimeStamp
:global ElectricityUpTimeDays
:global ElectricityUpTimeDaysFromVar
:global ElectricityUpTimeWeeks
:global ElectricityDownTime
:global ElectricityDownTimeStamp
:global ElectricityDownTimeDays
:global ElectricityDownTimeDaysFromVar
:global ElectricityDownTimeWeeks
:global PingerInterfaceName "sstp-out-electricity-ping"
:global PowerOnNotificationNeedToBeSent
:global PowerOffNotificationNeedToBeSent
# if nothing set in enviroment, false by default
:global DebugIsOn
# if nothing set in enviroment, PROD by default
:global env


# test and prod chat needed for DEV purposes
:local ChatID
:local prodChatID ""
:local testChatID ""
:local MessagePowerOn "\E2\9C\85 *Electricity Pinger Available* \E2\9C\85  %0a%0a\F0\9F\92\A1 Office Facility \F0\9F\92\A1%0a%0aWas Down for:"
:local MessagePowerOff "\E2\9D\8C *Electricity Pinger Unavailable* \E2\9D\8C  %0a%0a\F0\9F\95\AF Office Facility \F0\9F\95\AF%0a%0aWas Up for:"
:local TimeDaysMessage "d."
:local TimeHoursMessage "h."
:local TimeMinutesMessage "min."
##########################

:set $PingerIsRunning [/interface sstp-server get value-name=running [find where name=$PingerInterfaceName]]

:if ($PingerIsRunning) do={
        :if ([:typeof $ChecksFailedCount] = "nothing") do={
            :set $ChecksFailedCount 0
            :if ($DebugIsOn) do={
                :log warning "Fixed CheckFailedCount type nothing"
            }
        }

        :if ($ChecksFailedCount > 0) do={
            :set $ChecksFailedCount ($ChecksFailedCount - 1)
            }

} else={
        :if ($ChecksFailedCount < 15) do={
            :set $ChecksFailedCount ($ChecksFailedCount + 1)
        }

    }

# Default values checks
:if ([:typeof $env] = "nothing") do={
    :set $env "prod"
    }

:if ([:typeof $PowerOnNotificationNeedToBeSent] = "nothing") do={
            :set $PowerOnNotificationNeedToBeSent true
            :if ($DebugIsOn) do={
                :log warning "Fixed PowerOnNotificationNeedToBeSent type nothing"
            }
        }

:if ([:typeof $ElectricityUpTime] = "nothing") do={
    :set $ElectricityUpTime 00:00:00
    }

:if ([:typeof $ElectricityDownTime] = "nothing") do={
    :set $ElectricityDownTime 00:00:00
    }

:if ([:typeof $ElectricityUpTimeStamp] = "nothing") do={
    :set $ElectricityUpTimeStamp 00:00:00
    }

:if ([:typeof $ElectricityDownTimeStamp] = "nothing") do={
    :set $ElectricityDownTimeStamp 00:00:00
    }

:if ([:typeof $PowerOffNotificationNeedToBeSent] = "nothing") do={
            :set $PowerOffNotificationNeedToBeSent true
            :if ($DebugIsOn) do={
                :log warning "Fixed PowerOffNotificationNeedToBeSent type nothing"
            }
        }

:if ($env = "prod") do={
    :set $ChatID $prodChatID
    :if ($DebugIsOn) do={
        :log warning "ChatID set to PROD"
    }
} else={
    :if ($env = "test") do={
        :set $ChatID $testChatID
        :if ($DebugIsOn) do={
            :log warning "ChatID set to TEST"
    }
    }
}

:if ([:typeof $DebugIsOn] = "nothing") do={
    :set $DebugIsOn false
    }

:if ($ChecksFailedCount > 14) do={
    :if ($DebugIsOn) do={
    :log warning "Looks like the electricity is down"
    }
        :if ($DebugIsOn) do={
            :log error "Here the notification about powerOFF supposed to be sent, but debug is on, so just showing this message"
        } else={
            :if ($PowerOffNotificationNeedToBeSent) do={
            :log error "Notification was sent! | POWEROFF"
            :set $ElectricityDownTimeStamp [/system resource get value-name=uptime]
            :set $ElectricityUpTime ($ElectricityDownTimeStamp - $ElectricityUpTimeStamp + 00:01:15)
                            

            # Get weeks better
            :if ([:typeof [:find $ElectricityUpTime "w"]] = "num") do={
                #  Getting days num, in case if there is some days in uptime var
                :set $ElectricityUpTimeWeeks [:pick $ElectricityUpTime 0 ([:find $ElectricityUpTime "w"])]
            } else={
                :set $ElectricityUpTimeWeeks 0
            }

            # Calculate days and get days, if they're exist
            :if ([:typeof [:find $ElectricityUpTime "d"]] = "num") do={
                #  Getting days num, in case if there is some days in uptime var
                :set $ElectricityUpTimeDaysFromVar [:pick $ElectricityUpTime ([:find $ElectricityUpTime "d"]-1) ([:find $ElectricityUpTime "d"])]
            } else={
                :set $ElectricityUpTimeDaysFromVar 0
            }

            # Calculate days from weeks + days getted
            :set $ElectricityUpTimeDays ($ElectricityUpTimeDaysFromVar + ($ElectricityUpTimeWeeks * 7))
            # Get Hours
            :local ElectricityUpTimeHours [:pick $ElectricityUpTime ([:find $ElectricityUpTime ":"]-2) ([:find $ElectricityUpTime ":"])]
            # Get Minutes                               
            :local ElectricityUpTimeMinutes [:pick $ElectricityUpTime ([:find $ElectricityUpTime ":"]+1) ([:find $ElectricityUpTime ":"]+3)]

            /tool fetch url="https://api.telegram.org/bot807851933:AAGd91oDpO6eWCrnA-deYsdYovAssaU_-ug/sendMessage\?chat_id=$ChatID&text=$MessagePowerOff $ElectricityUpTimeDays $TimeDaysMessage $ElectricityUpTimeHours $TimeHoursMessage $ElectricityUpTimeMinutes $TimeMinutesMessage" keep-result=no
            :set $PowerOnNotificationNeedToBeSent true
            :set $PowerOffNotificationNeedToBeSent false
            :delay 1
            :set $ElectricityUpTime 00:00:00
            :set $ElectricityUpTimeStamp 00:00:00
            } else={
                :if ($DebugIsOn) do={
                    :log warning "No powerOFF notification needs to be sent, because of PowerOffNotificationNeedToBeSent is $PowerOffNotificationNeedToBeSent"
                }
            }
        }

 } else={
    :if ($ChecksFailedCount = 0) do={
                :if ($DebugIsOn) do={
                :log warning "Looks like the electricity is up again"
                }
                    :if ($DebugIsOn) do={
                        :log error "Here the notification about powerON supposed to be sent, but debug is on, so just showing this message"
                    } else={
                        :if ($PowerOnNotificationNeedToBeSent) do={
                            :log error "Notification was sent! | POWERON"
                            :set $ElectricityUpTimeStamp [/system resource get value-name=uptime]
                            :set $ElectricityDownTime ($ElectricityUpTimeStamp - $ElectricityDownTimeStamp + 00:01:15)
                                
            # Get weeks better
            :if ([:typeof [:find $ElectricityDownTime "w"]] = "num") do={
                #  Getting days num, in case if there is some days in uptime var
                :set $ElectricityDownTimeWeeks [:pick $ElectricityDownTime 0 ([:find $ElectricityDownTime "w"])]
            } else={
                :set $ElectricityDownTimeWeeks 0
            }

            # Calculate days and get days, if they're exist
            :if ([:typeof [:find $ElectricityDownTime "d"]] = "num") do={
                #  Getting days num, in case if there is some days in uptime var
                :set $ElectricityDownTimeDaysFromVar [:pick $ElectricityDownTime ([:find $ElectricityDownTime "d"]-1) ([:find $ElectricityDownTime "d"])]   
            } else={
                 :set $ElectricityDownTimeDaysFromVar 0
            }

                                # Calculate days from weeks + days getted
                                :set $ElectricityDownTimeDays ($ElectricityDownTimeDaysFromVar + ($ElectricityDownTimeWeeks * 7))
                                # Get Hours
                                :local ElectricityDownTimeHours [:pick $ElectricityDownTime ([:find $ElectricityDownTime ":"]-2) ([:find $ElectricityDownTime ":"])]
                                # Get Minutes                               
                                :local ElectricityDownTimeMinutes [:pick $ElectricityDownTime ([:find $ElectricityDownTime ":"]+1) ([:find $ElectricityDownTime ":"]+3)]
                            
                            /tool fetch url="https://api.telegram.org/bot807851933:AAGd91oDpO6eWCrnA-deYsdYovAssaU_-ug/sendMessage\?chat_id=$ChatID&text=$MessagePowerOn $ElectricityDownTimeDays $TimeDaysMessage $ElectricityDownTimeHours $TimeHoursMessage $ElectricityDownTimeMinutes $TimeMinutesMessage" keep-result=no
                            :set $PowerOnNotificationNeedToBeSent false
                            :set $PowerOffNotificationNeedToBeSent true
                            :delay 1
                            :set $ElectricityDownTime 00:00:00
                            :set $ElectricityDownTimeStamp 00:00:00
                        } else={
                        :if ($DebugIsOn) do={
                            :log warning "No powerON notification needs to be sent, because of PowerOnNotificationNeedToBeSent is $PowerOnNotificationNeedToBeSent"
                        }
                        }
                    }
                
    }
 }
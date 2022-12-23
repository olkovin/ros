# electricity down detector
# based on sstp client and Mikrotik ROS

:global epsstpDM75ChecksFailedCount
:global epsstpDM75PingerIsRunning
:global epsstpDM75ElectricityUpTime
:global epsstpDM75ElectricityUpTimeStamp
:global epsstpDM75ElectricityDownTime
:global epsstpDM75ElectricityDownTimeStamp
:global epsstpDM75PingerInterfaceName "sstp-out-electricity-ping"
:global epsstpDM75PowerOnNotificationNeedToBeSent
:global epsstpDM75PowerOffNotificationNeedToBeSent

# if nothing set in enviroment, false by default
:global epsstpDM75DebugIsOn

# if nothing set in enviroment, PROD by default
:global epsstpDM75env


# local params for message sendings
:local ChatID
:local prodChatID ""
:local testChatID ""
:local botapitoken ""

# Unicode was used, because RouterOS doesn't support the Cyrillic symbols
# %0a -- new line

:local MessagePowerOn "\E2\9C\85 *\D0\A1\D0\B2\D1\96\D1\82\D0\BB\D0\BE\20\D0\B7\CA\BC\D1\8F\D0\B2\D0\B8\D0\BB\D0\BE\D1\81\D1\8C* \E2\9C\85  %0a%0a\F0\9F\92\A1 \D0\94\D0\BC\D0\B8\D1\82\D1\80\D1\96\D0\B2\D1\81\D1\8C\D0\BA\D0\B0\20\37\35\2C\20\D0\BF\2E\32 \F0\9F\92\A1%0a%0a\F0\9F\95\90\20\D0\9D\D0\B5\20\D0\BF\D1\80\D0\B0\D1\86\D1\8E\D0\B2\D0\B0\D0\BB\D0\BE\3A\20"
:local MessagePowerOff "\E2\9D\8C *\D0\A1\D0\B2\D1\96\D1\82\D0\BB\D0\BE\20\D0\B7\D0\BD\D0\B8\D0\BA\D0\BB\D0\BE* \E2\9D\8C  %0a%0a\F0\9F\95\AF \D0\94\D0\BC\D0\B8\D1\82\D1\80\D1\96\D0\B2\D1\81\D1\8C\D0\BA\D0\B0\20\37\35\2C\20\D0\BF\2E\32 \F0\9F\95\AF%0a%0a\F0\9F\95\90\20\D0\9F\D1\80\D0\B0\D1\86\D1\8E\D0\B2\D0\B0\D0\BB\D0\BE\3A\20"
:local TimeHoursMessage "\D0\B3\D0\BE\D0\B4"
:local TimeMinutesMessage "\D1\85\D0\B2"

##########################

# Default values check and charge

:if ([:typeof $epsstpDM75env] = "nothing") do={
    :set $epsstpDM75env "prod"
    }

:if ([:typeof $epsstpDM75PowerOnNotificationNeedToBeSent] = "nothing") do={
            :set $epsstpDM75PowerOnNotificationNeedToBeSent true
            :if ($epsstpDM75DebugIsOn) do={
                :log warning "Fixed epsstpDM75PowerOnNotificationNeedToBeSent type nothing"
            }
        }

:if ([:typeof $epsstpDM75ElectricityUpTime] = "nothing") do={
    :set $epsstpDM75ElectricityUpTime 00:00:00
    }

:if ([:typeof $epsstpDM75ElectricityDownTime] = "nothing") do={
    :set $epsstpDM75ElectricityDownTime 00:00:00
    }

:if ([:typeof $epsstpDM75ElectricityUpTimeStamp] = "nothing") do={
    :set $epsstpDM75ElectricityUpTimeStamp 00:00:00
    }

:if ([:typeof $epsstpDM75ElectricityDownTimeStamp] = "nothing") do={
    :set $epsstpDM75ElectricityDownTimeStamp 00:00:00
    }

:if ([:typeof $epsstpDM75PowerOffNotificationNeedToBeSent] = "nothing") do={
            :set $epsstpDM75PowerOffNotificationNeedToBeSent true
            :if ($epsstpDM75DebugIsOn) do={
                :log warning "Fixed epsstpDM75PowerOffNotificationNeedToBeSent type nothing"
            }
        }

:if ([:typeof $epsstpDM75ChecksFailedCount] = "nothing") do={
    :set $epsstpDM75ChecksFailedCount 0
    :if ($epsstpDM75DebugIsOn) do={
        :log warning "Fixed CheckFailedCount type nothing"
        }
}

:if ($epsstpDM75env = "prod") do={
    :set $ChatID $prodChatID
    :if ($epsstpDM75DebugIsOn) do={
        :log warning "ChatID set to PROD"
    }
} else={
    :if ($epsstpDM75env = "test") do={
        :set $ChatID $testChatID
        :if ($epsstpDM75DebugIsOn) do={
            :log warning "ChatID set to TEST"
    }
    }
    }

:if ([:typeof $epsstpDM75DebugIsOn] = "nothing") do={
    :set $epsstpDM75DebugIsOn false
    }

########

:set $epsstpDM75PingerIsRunning [/interface sstp-server get value-name=running [find where name=$epsstpDM75PingerInterfaceName]]

:if ($epsstpDM75PingerIsRunning) do={

        :if ($epsstpDM75ChecksFailedCount > 0) do={
            :set $epsstpDM75ChecksFailedCount ($epsstpDM75ChecksFailedCount - 1)
            }

} else={
        :if ($epsstpDM75ChecksFailedCount < 15) do={
            :set $epsstpDM75ChecksFailedCount ($epsstpDM75ChecksFailedCount + 1)
        }

    }

:if ($epsstpDM75ChecksFailedCount > 14) do={
    :if ($epsstpDM75DebugIsOn) do={
    :log warning "Looks like the electricity is down"
    }
        :if ($epsstpDM75DebugIsOn) do={
            :log error "Here the notification about powerOFF supposed to be sent, but debug is on, so just showing this message"
        } else={
            :if ($epsstpDM75PowerOffNotificationNeedToBeSent) do={
            :log error "Notification was sent! | POWEROFF"
            :set $epsstpDM75ElectricityDownTimeStamp [/system resource get value-name=uptime]
            :set $epsstpDM75ElectricityUpTime ($epsstpDM75ElectricityDownTimeStamp - $epsstpDM75ElectricityUpTimeStamp + 00:01:15)
                :local ElectricityUpTimeHours [:pick $epsstpDM75ElectricityUpTime ([:find $epsstpDM75ElectricityUpTime ":"]-2) ([:find $epsstpDM75ElectricityUpTime ":"])]
                :local ElectricityUpTimeMinutes [:pick $epsstpDM75ElectricityUpTime ([:find $epsstpDM75ElectricityUpTime ":"]+1) ([:find $epsstpDM75ElectricityUpTime ":"]+3)]
            /tool fetch url="https://api.telegram.org/$botapitoken/sendMessage\?chat_id=$ChatID&text=$MessagePowerOff $ElectricityUpTimeHours $TimeHoursMessage $ElectricityUpTimeMinutes $TimeMinutesMessage" keep-result=no
            :set $epsstpDM75PowerOnNotificationNeedToBeSent true
            :set $epsstpDM75PowerOffNotificationNeedToBeSent false
            :delay 1
            :set $epsstpDM75ElectricityUpTime 00:00:00
            :set $epsstpDM75ElectricityUpTimeStamp 00:00:00
            } else={
                :if ($epsstpDM75DebugIsOn) do={
                    :log warning "No powerOFF notification needs to be sent, because of epsstpDM75PowerOffNotificationNeedToBeSent is $epsstpDM75PowerOffNotificationNeedToBeSent"
                }
            }
        }

 } else={
    :if ($epsstpDM75ChecksFailedCount = 0) do={
                :if ($epsstpDM75DebugIsOn) do={
                :log warning "Looks like the electricity is up again"
                }
                    :if ($epsstpDM75DebugIsOn) do={
                        :log error "Here the notification about powerON supposed to be sent, but debug is on, so just showing this message"
                    } else={
                        :if ($epsstpDM75PowerOnNotificationNeedToBeSent) do={
                            :log error "Notification was sent! | POWERON"
                            :set $epsstpDM75ElectricityUpTimeStamp [/system resource get value-name=uptime]
                            :set $epsstpDM75ElectricityDownTime ($epsstpDM75ElectricityUpTimeStamp - $epsstpDM75ElectricityDownTimeStamp + 00:01:15)
                                :local ElectricityDownTimeHours [:pick $epsstpDM75ElectricityDownTime ([:find $epsstpDM75ElectricityDownTime ":"]-2) ([:find $epsstpDM75ElectricityDownTime ":"])]
                                :local ElectricityDownTimeMinutes [:pick $epsstpDM75ElectricityDownTime ([:find $epsstpDM75ElectricityDownTime ":"]+1) ([:find $epsstpDM75ElectricityDownTime ":"]+3)]


                            /tool fetch url="https://api.telegram.org/$botapitoken/sendMessage\?chat_id=$ChatID&text=$MessagePowerOn $ElectricityDownTimeHours $TimeHoursMessage $ElectricityDownTimeMinutes $TimeMinutesMessage" keep-result=no
                            :set $epsstpDM75PowerOnNotificationNeedToBeSent false
                            :set $epsstpDM75PowerOffNotificationNeedToBeSent true
                            :delay 1
                            :set $epsstpDM75ElectricityDownTime 00:00:00
                            :set $epsstpDM75ElectricityDownTimeStamp 00:00:00
                        } else={
                        :if ($epsstpDM75DebugIsOn) do={
                            :log warning "No powerON notification needs to be sent, because of epsstpDM75PowerOnNotificationNeedToBeSent is $epsstpDM75PowerOnNotificationNeedToBeSent"
                        }
                        }
                    }
                
    }
 }
# electricity down detector
# based on sstp client and Mikrotik ROS

:global ChecksFailedCount
:global PingerIsRunning
:global ElectricityUpTime
:global ElectricityUpTimeStamp
:global ElectricityDownTime
:global ElectricityDownTimeStamp
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
:local MessagePowerOn "\E2\9C\85 *\D0\A1\D0\B2\D1\96\D1\82\D0\BB\D0\BE\20\D0\B7\CA\BC\D1\8F\D0\B2\D0\B8\D0\BB\D0\BE\D1\81\D1\8C* \E2\9C\85  %0a%0a\F0\9F\92\A1 \D0\94\D0\BC\D0\B8\D1\82\D1\80\D1\96\D0\B2\D1\81\D1\8C\D0\BA\D0\B0\20\37\35\2C\20\D0\BF\2E\32 \F0\9F\92\A1%0a%0a\F0\9F\95\90\20\D0\9D\D0\B5\20\D0\BF\D1\80\D0\B0\D1\86\D1\8E\D0\B2\D0\B0\D0\BB\D0\BE\3A\20"
:local MessagePowerOff "\E2\9D\8C *\D0\A1\D0\B2\D1\96\D1\82\D0\BB\D0\BE\20\D0\B7\D0\BD\D0\B8\D0\BA\D0\BB\D0\BE* \E2\9D\8C  %0a%0a\F0\9F\95\AF \D0\94\D0\BC\D0\B8\D1\82\D1\80\D1\96\D0\B2\D1\81\D1\8C\D0\BA\D0\B0\20\37\35\2C\20\D0\BF\2E\32 \F0\9F\95\AF%0a%0a\F0\9F\95\90\20\D0\9F\D1\80\D0\B0\D1\86\D1\8E\D0\B2\D0\B0\D0\BB\D0\BE\3A\20"
:local TimeDaysMessage "\D0\B4\D0\BD"
:local TimeHoursMessage "\D0\B3\D0\BE\D0\B4"
:local TimeMinutesMessage "\D1\85\D0\B2"
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
                            
            # Get Weeks
            :local ElectricityUpTimeWeeks [:pick $ElectricityUpTime 0 ([:find $ElectricityUpTime "w"])]
            # Calculate days and get days, if they're exist
            :local ElectricityUpTimeDaysDetection false
            :if ((:typeof [:find $testtime "d"]) = "num") do={
                #  Getting days num, in case if there is some days in uptime var
                :local ElectricityUpTimeDaysFromVar [:pick $ElectricityUpTime ([:find $ElectricityUpTime "w"]+1) ([:find $ElectricityUpTime "d"])]
            } else={
                # Setting 0 to days, in case if there is no days in uptime var
                :if ((:typeof [:find $testtime "d"]) = "nil") do={
                    :local ElectricityUpTimeDaysFromVar 0
                }
            }
            # Calculate days from weeks + days getted
            :local ElectricityUpTimeDays ($ElectricityUpTimeDaysFromVar + ($ElectricityUpTimeWeeks) * 7)
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
                                
                                # Get Weeks
                                :local ElectricityDownTimeWeeks [:pick $ElectricityDownTime 0 ([:find $ElectricityDownTime "w"])]
                                # Calculate days and get days, if they're exist
                                :local ElectricityDownTimeDaysDetection false
                                :if ((:typeof [:find $testtime "d"]) = "num") do={
                                    #  Getting days num, in case if there is some days in uptime var
                                    :local ElectricityDownTimeDaysFromVar [:pick $ElectricityDownTime ([:find $ElectricityDownTime "w"]+1) ([:find $ElectricityDownTime "d"])]
                                } else={
                                    # Setting 0 to days, in case if there is no days in uptime var
                                    :if ((:typeof [:find $testtime "d"]) = "nil") do={
                                        :local ElectricityDownTimeDaysFromVar 0
                                    }
                                }
                                # Calculate days from weeks + days getted
                                :local ElectricityDownTimeDays ($ElectricityDownTimeDaysFromVar + ($ElectricityDownTimeWeeks) * 7)
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
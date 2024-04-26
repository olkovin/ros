# XML domains parser for RouterOS
# t.me/olekovin
# k2o.cc
# ver 1.5.0
# K2ODOMAINSPARSER_anchor
# From a friend for a friend :)

# Set the name of the address list and XML file name
:global k2oxmlparserAddressListName "register.xml-list"
:global k2oxmlparserXMLFileName "register.xml"
:global k2oxmlparserLastProcessedDate

# Advanced settings for the script
:local lockFileName "k2oxmlparser.lock"
:local k2oxmparserscriptname "k2oxmlparser"
:local k2oxmlparserscriptowner "k2oxmlparser-script"

# If set to true, the script will force the address list to run ignorign last processed date
:local forcerunenabled true

# will delete all entries from the address list after the script is run and timeout
:local testrun false
:local testruntimeout 10

# Changing owner and script name
:do {
    /system script set owner=$k2oxmlparserscriptowner name=$k2oxmparserscriptname comment="XML Domains parsing script with adding them to address list" [find where source~"K2ODOMAINSPARSER_anchor" && owner!="$k2oxmlparserscriptowner"]
} on-error={
    :log error "$k2oxmparserscriptname: Error when changing owner and script name. ERRNO:32"
}

# Check if the lock file exists to ensure the script does not run multiple times
:if ([:len [/file find name=$lockFileName]] > 0) do={
    :log debug "$k2oxmparserscriptname: Script is already running."
    :log debug "$k2oxmparserscriptname: Script execution locked."
} else {

    # Create a lock file
    :log debug "$k2oxmparserscriptname: Creating lock file to prevent multiple script executions."
    /file print file=$lockFileName

    # Load the XML data from the file and check the creation date
    :log debug "$k2oxmparserscriptname: Checking XML file..."
    :local currentFileCreationDate [/file get [find name=$k2oxmlparserXMLFileName] creation-time]

    # Compare the current file creation date with the last processed date
    :if ($currentFileCreationDate != $k2oxmlparserLastProcessedDate || $forcerunenabled) do={
        :if ($forcerunenabled) do={
            :log debug "$k2oxmparserscriptname: Force run enabled. Running the script regardless of the last processed date."
        } else={
            :log debug "$k2oxmparserscriptname: XML file has been updated since last check. Last processed date: $k2oxmlparserLastProcessedDate"
        }
        :set $k2oxmlparserLastProcessedDate $currentFileCreationDate
        :local xmlData [/file get [find name=$k2oxmlparserXMLFileName] contents]
        :log debug "$k2oxmparserscriptname: XML file loaded."
        :log debug "$k2oxmparserscriptname: Initializing variables..."
        # Initialize variables to manage the parsing loop
        :local startPos 0
        :local entryStart 0
        :local entryEnd 0
        :local domainStart 0
        :local domainEnd 0
        :local domainValue ""
        :local dateStart 0
        :local dateEnd 0
        :local dateValue ""
        :local lpValue ""
        :local commentValue ""
        :local xmlParserIterations

        # Setting iterations according to script lenght 
        # Yeah yeah, clumsy approach, I know
        :set $xmlParserIterations ([:len $xmlData] / 5)
        :log debug "XMLiterations $xmlParserIterations"
        # Loop to extract data from XML entries
        :log debug "$k2oxmparserscriptname: Parsing XML data..."
        :while ($xmlParserIterations > 0) do={
            # Decrease the number of iterations
            :log debug "$k2oxmparserscriptname: Iterations left: $xmlParserIterations"
            :set $xmlParserIterations ($xmlParserIterations - 1)
            :log  debug "Parsing entry at position $startPos"
            :set $entryStart [:find $xmlData "<PozycjaRejestru" $startPos]
            :if ($entryStart = -1) do={
                :set $startPos [:len $xmlData]; 
                }
            :set $entryEnd [:find $xmlData "</PozycjaRejestru>" $entryStart]
            :set $startPos ($entryEnd + 16)

            # Extract the 'Lp' attribute
            :set $lpValue [:pick $xmlData ([:find $xmlData "Lp=\"" $entryStart] + 4) [:find $xmlData "\"" ([:find $xmlData "Lp=\"" $entryStart] + 4)]]

            # Extract 'AdresDomeny'
            :set $domainStart ([:find $xmlData "<AdresDomeny>" $entryStart] + 13)
            :set $domainEnd [:find $xmlData "</AdresDomeny>" $domainStart]
            :set $domainValue [:pick $xmlData $domainStart $domainEnd]

            # Extract 'DataWpisu'
            :set $dateStart ([:find $xmlData "<DataWpisu>" $entryStart] + 11)
            :set $dateEnd [:find $xmlData "</DataWpisu>" $dateStart]
            :set $dateValue [:pick $xmlData $dateStart $dateEnd]

            # Combine 'LP' and 'DataWpisu' for the comment with the new format
            :set $commentValue ("LP: " . $lpValue . " | Timestamp: " . $dateValue)

            # Check if the domain is already in the address list with the same comment
            :if ([:len [/ip firewall address-list find where address=$domainValue and comment=$commentValue]] = 0) do={
                /ip firewall address-list add list=$k2oxmlparserAddressListName address=$domainValue comment=$commentValue
            } else={
                :log debug "$k2oxmparserscriptname: Domain $domainValue with comment $commentValue already exists in the address list. Skipping..."
            }
        }
    } else {
        :log debug "$k2oxmparserscriptname: No update to the XML file since last check. Last processed date: $k2oxmlparserLastProcessedDate"
    }

    # If test run is enabled, remove all entries from the address list after the timeout
    :if ($testrun) do={
        :log debug "$k2oxmparserscriptname: Test run enabled. Deleting all entries from the address list in $testruntimeout seconds."
        :delay $testruntimeout
        /ip firewall/address-list remove [find where list=$k2oxmlparserAddressListName && dynamic=no]
    }

    # Remove the lock file after processing
    /file remove $lockFileName
}
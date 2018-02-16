#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Copyright (c) 2017 Jamf.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the Jamf nor the names of its contributors may be
#                 used to endorse or promote products derived from this software without
#                 specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# What is scoped to my Computer Groups?
#
# In this script we will utilize the Jamf Pro API to determine what Policies, Configuration
# Profiles, Restricted Software, Mac App Store Apps and eBooks are assigned to your
# Computer Groups.
#
# OBJECTIVES
#       - Create a list of all Smart Groups
#       - Provide a list of what is scoped to each Smart Group
#
# For more information, visit https://github.com/kc9wwh/JamfProGroupsScoped
#
#
# Written by: Joshua Roskos | Professional Services Engineer | Jamf
#
# Created On: October 2nd, 2017
# Updated On: October 26th, 2017
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# VARIABLES
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

jamfURL="https://acme.jamfcloud.com"
jamfUser="apiread"
jamfPass="password"
currentUser=$(/usr/bin/stat -f%Su /dev/console)

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# FUNCTIONS
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

## Function Format - findScopedObjects
## $1: Object Type (Policy, Configuration Profile, Restricted Software, Mac App Store App, eBook)
## $2: Object API Endpoint (policies, osxconfigurationprofiles, restrictedsoftware, macapplications, ebooks)
## $3: xpath/XML Tree - Top Level Only (policy, os_x_configuration_profile, restricted_software, mac_application, ebook)
function findScopedObjects() {
    echo "Retrieving List of All $1 IDs..."
    unset objectIDs
    objectIDs=( $( curl -k -s -u "$jamfUser":"$jamfPass" $jamfURL/JSSResource/$2 -H "Accept: application/xml" -X GET | /usr/bin/perl -lne 'BEGIN{undef $/} while (/<id>(.*?)<\/id>/sg){print $1}' ) )
    for i in "${objectIDs[@]}"; do
        echo "Retrieving $1 ID ${i}'s' Data..."
        objectData=$( curl -k -s -u "$jamfUser":"$jamfPass" $jamfURL/JSSResource/$2/id/${i} -H "Accept: application/xml" -X GET )
        objectName=$( echo $objectData | xpath "//$3/general/name/text()" )
        if [[ "$1" == "Policy" ]]; then
            ## Check if is a Jamf Remote Policy
            echo "Checking if this is a Jamf Remote Policy..."
            if [[ $objectName == $( echo $objectName | egrep -B1 '[0-9]+-[0-9]{2}-[0-9]{2} at [0-9]{1,2}:[0-9]{2,2} [AP]M \| .* \| .*' ) ]]; then
                ## This is a Jamf Remote Policy
                ## Setting policy name in array to "JamfRemotePolicy-Ignore"
                echo "    This is a Jamf Remote policy"
                continue
            else
                ## This is NOT a Casper Remote Policy
                ## Storing Policy Name and Grabbing Scope Data
                echo "    This is a standard policy"
                ## Extract Scoped Computer Group ID(s)
                unset grpID
                grpID=( $( echo $objectData | /usr/bin/perl -lne 'BEGIN{undef $/} while (/<computer_groups>(.*?)<\/computer_groups>/sg){print $1}' | /usr/bin/perl -lne 'BEGIN{undef $/} while (/<id>(.*?)<\/id>/sg){print $1}' ) )
                if [[ ${#grpID[@]} -eq 0 ]]; then
                    echo "No Computer Groups Scoped in $1 ${objectIDs[$i]}..."
                else
                    echo "Computer Groups found for $1 ${objectIDs[$i]}..."
                    for n in "${grpID[@]}"; do
                        eval compGrp$n+=\(\"$objectName \($1\)\"\)
                    done
                fi
            fi
        else
            unset grpID
            grpID=( $( echo $objectData | /usr/bin/perl -lne 'BEGIN{undef $/} while (/<computer_groups>(.*?)<\/computer_groups>/sg){print $1}' | /usr/bin/perl -lne 'BEGIN{undef $/} while (/<id>(.*?)<\/id>/sg){print $1}' ) )
            if [[ ${#grpID[@]} -eq 0 ]]; then
                echo "No Computer Groups Scoped in $1 ${objectIDs[$i]}..."
            else
                echo "Computer Groups found for $1 ${objectIDs[$i]}..."
                for n in "${grpID[@]}"; do
                    eval compGrp$n+=\(\"$objectName \($1\)\"\)
                done
            fi
        fi
        sleep .3
    done
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# APPLICATION
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

## Retrieve & Extract Computer Group IDs/Names & Build Array
compGroupData=$( curl -k -s -u "$jamfUser":"$jamfPass" $jamfURL/JSSResource/computergroups -H "Accept: application/xml" -X GET )
compGrpSize=$( echo $compGroupData | xpath "//computer_groups/size/text()" )

## Error handling for computer group data and size

if [[ ${#compGroupData} -lt 2 || $compGrpSize == 0 ]] ; then
	echo "ERROR: No groups were downloaded.  Please verify connection to the JSS."
	exit 2
fi

if [[ -n $(echo $compGroupData | grep -o "Unauthorized") ]]; then
	echo "ERROR: JSS rejected the API credentials.  Please double-check the script and run again."
	exit 1
fi

index=0
declare -a compGrpNames
declare -a compGrpIDs
while [ $index -lt ${compGrpSize} ]; do
    element=$(($index+1))
    compGrpName=$( echo $compGroupData | xpath "//computer_groups/computer_group[${element}]/name/text()" )
    compGrpID=$( echo $compGroupData | xpath "//computer_groups/computer_group[${element}]/id/text()" )
    echo "Computer Group ID: $compGrpID"
    echo "Computer Group Name: $compGrpName"
    compGrpNames[$index]="$compGrpName"
    compGrpIDs[$index]="$compGrpID"
    declare -a compGrp${compGrpID}
    ((index++))
done

## Check Policies, Configuration Profiles, Restircted Software and Mac App Store Apps
findScopedObjects "Policy" "policies" "policy"
findScopedObjects "Configuration Profile" "osxconfigurationprofiles" "os_x_configuration_profile"
findScopedObjects "Restricted Software" "restrictedsoftware" "restricted_software"
findScopedObjects "Mac App Store App" "macapplications" "mac_application"
findScopedObjects "eBook" "ebooks" "ebook"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# BUILD HTML REPORT
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

reportDate=$(/bin/date "+%Y-%m-%d %H%M%S")
reportName="/Users/${currentUser}/Desktop/Jamf Pro Computer Group Report - $reportDate.html"
echo "<html>
<head>
<title>Jamf Pro Computer Groups Report - $reportDate</title>
</head>
<body>
<h1>Jamf Pro Computer Groups Report</h1>
<i>Report Date: $reportDate<br/>Jamf Pro server: $jamfURL</i>
<hr/>
<p/>" > "$reportName"
for (( x = 0 ; x < ${#compGrpNames[@]} ; x++ )); do
    echo "<b>${compGrpNames[$x]}</b><br/><ul>" >> "$reportName"
    groupID="${compGrpIDs[$x]}"
    yCount=$(eval echo \${#compGrp$groupID[@]})
    for (( y = 0 ; y < $yCount ; y++ )); do
        echo "<li>$(eval echo \${compGrp$groupID[$y]})</li>" >> "$reportName"
    done
    echo "</ul><p/>" >> "$reportName"
done
echo "</body>
</html>" >> "$reportName"

open "$reportName"

exit 0

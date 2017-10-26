![logo](/resources/logo.png)
# JamfProGroupsScoped
###### Have you ever wanted to know what was scoped to your Jamf Pro groups? Well, now you can!
___
This script was created to help you understand what is actually scoped to your groups in Jamf Pro. The script will check against Computer Policies, Configuration Profiles, Restricted Software, Mac App Store apps and eBooks.

Requirements:
* Jamf Pro
* API Read Only User

Written By: Joshua Roskos | Professional Services Engineer | Jamf

Created On: October 2nd, 2017 | Updated On: October 26th, 2017
___

### Why is this needed?

As our Jamf Pro environments grow, we're always adding groups to use for scoping applications, reporting or checking compliance. But as applications and our environment changes, these groups end up getting replaced by others, however how do we truly know that group isn't attached to a policy somewhere that is going to affect your environment in a very negative way? Well, now we can check and see what is actually using all those groups we've accumulated over the years.


### Implementation

**Step 1 - Configure the Script**

When you open the script you will find some user variables that will need to be defined as specified below:
* CompGroupsScoped.sh - Lines 57-60


**Step 2 - Run the Script**

* Launch *Terminal*
* Ensure Script is Executable: *chmod +x /path/to/CompGroupsScoped.sh*
* Run the Script: *./path/to/CompGroupsScoped.sh*

**Step 3 - View the Report & Enjoy!**

*The report should have auto-opened in your default browser. Otherwise it will also be saved to your desktop.*

![Sample Report](/resources/Jamf%20Pro%20Computer%20Groups%20Report%20Sample.png)

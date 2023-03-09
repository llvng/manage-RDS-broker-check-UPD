# Check for mounted/unmounted User Profile Disks (UPDs)

Managing User Profile Disks can be quite cumbersome and after we experienced some recent issues, I put together a script that would collect and compare some data to help us diagnose this issue.

Our clients were getting temporary profiles due to unclean disconnects/logoffs locking up the UPDs and we wanted to gather data to see if there was a pattern to this.

The UPDs are all managed by the Security Identifiers (SIDs) rather than usernames. You can use a tool like Sidder to see which UPD belongs to who but this script will do it programmatically.

In our situation, the User Profile Disks were stored on the same server as the broker, so this script runs local commands from the broker - it can be modified to get data from another server if this is where your UPDs are stored, such as a file server, but it should be run from the Broker.

The script will carry out the following:
- Create a list of all active sessions and their SIDs
  - This object is then referenced for future lookups
- Create a table of all the active sessions from your Remote Desktop Session Hosts (RDSH) and their states - Connected, Active or Disconnected
- Calculate how many users are logged onto which RDSHs
- Check if the user has managed to log onto multiple RDSH
  - i.e. they have more than one active user session
- Create a list of all of the active open VHDX files (UPDs) and their usernames agains them
- Compare the list of VHDX with Active sessions and return any users that:
  - Have an active RD Session but do NOT have a mounted UPD
  - Have a mounted UPD but do NOT have an active RD Session
  *- Both of these instances will likely cause temporary profile issues*
  
 It will return all of this information in a friendly PowerShell Window and can be run quite lightweight to ascertain which users may be having issues.
 
 I also wrote another script which looks up the "ProfileList" key in each of the RDSH's to see if there are any ones with .bak extensions. *Another indicator of temporary profiles*. I may upload this one too but need to remove some client data.

![image](https://user-images.githubusercontent.com/34309084/224012342-9e81958a-fa79-4467-b04d-7eecc4fcddb5.png)

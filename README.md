
### **COMPLETELY UNSUPPORTED - USE AT YOUR OWN RISK**

### Usage

- SSH into Ops Manager
- Log in to your BOSH director (`bosh --ca-cert /var/tempest/workspaces/default/root_ca_certificate target DIRECTOR-IP-ADDRESS`)
- Target your cf deployment (`bosh deployment DEPLOYMENT-FILENAME.yml`)
- Run `pcf-start-stop.sh (start | stop) [--hard]`
 - Optionally, add to crontab to schedule

### NOTE
**HA deployments** - Consul clusters have some real issues coming back from the dead, the script will check the number of Consul jobs in the targeted deployment and abort if more than 1 is found.

You can only use the `--hard` argument if you have chosen 'external' options for the system blobstore and system database. The script will check for `nfs_server` and `mysql` jobs and exit without doing anything if either one is found.

A `--hard` stop takes ~30min to complete. A `start` after a hard stop takes around the same amount of time. You probably want to run this via `tmux` or `screen`.

And as of now, this script works with PCF 1.9 and above only!

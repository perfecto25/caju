## Sample TOML config 

[defaults]
alert.repeat = "yes" # repeat alert on each cycle
alert.groups = "all" # alert all configured groups
alert.users = "all"


[[filesystem]]
path = "root"
trig = [80,90,95]
alert.groups = "sysadmins"

[[filesystem]]
path = "/home"
trig = 90

[memory]
trig = [50,60,80]

[cpu]
trig = [90] # cpu usage above 90
loadavg.trig = 30 # load average above 30

[[script]]
path = "/home/user/script.sh" # custom shell script check (returns 2 values, shell output 1/0 and message, ie
# 0, "no issues"
# 1, "error, some error happened"


[[script]]
path = "/opt/check.sh" # more custom checks



# wininstall

A simple bash script that installs a Windows WIM file into a specified partition, then uses BCD-SYS to generate and copy boot files into the EFI partition.

I never published this until my main laptop (either the DC jack itself or the charger is broken in some way) was basically turned into a brick. (it runs at 400mhz and can't charge the battery. fuck you DELL.) I'm typing this on a DELL Inspiron from 2012 which runs faster than that DELL 15 from 2025 somehow.

## Usage

This script requires `wget` and `wimlib-utils` to run.

```
sudo ./wiminstall.bash -w [winpart] -e [efipart] -f [wimfile]
-i specifies the index and is optional. when not specified, the script will show available indexes on the WIM to choose from.
```

## Credits
[BCD-SYS](https://github.com/jpz4085/BCD-SYS)

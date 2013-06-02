snapback.ps1
============

A Powershell script for convenient Windows backups using Drive Snapshot (http://www.drivesnapshot.de/en/index.htm)

Why Drive Snapshot?
-------------------

Drive Snapshot is a nice disk imaging utility for Windows. You can save complete systems to image files during
normal operation. It does not need to be installed permanently and comes in a very small .exe file. I backup my
virtual machines from the inside, with minimum daily backup space, and I'm still able to restore single files or
complete systems easily.


Why this script?
----------------

Drive Snapshot brings only the basic functions, this script provides automation of my backup strategy. snapback.ps1
uses differential images, and creates a new full image automatically when the diffs get too big.

How to use
----------

At the moment all config variables are directly in the script, no external config yet.


Questions?
----------
Ask me: kav@violka-it.de

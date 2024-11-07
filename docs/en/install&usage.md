# Install

1. Install the script part from the **pack** archive from the latest release as a regular content pack

2. Download the software part of the content pack
- If you are on **Windows** - download the **batch** archive from the latest release
- If you are on **Linux**/**MacOS** - download the **bash** archive from the latest release


After downloading the archive:
1) If you do not use the launcher and launch the engine manually, then unpack it into the engine folder

2) If you use a launcher, then unpack the archive into the folder where you store user data (in particular folders such as: **worlds**, **exports**, **configs**, etc.)

# Start

If you are on **Windows**:
1) If you start the engine manually, now for convenience you can do this through the script **vccurl_master.bat**. It will run the script **vccurl_replier.bat** and will automatically close it after the engine is closed.
2) If you launch the engine through the launcher, then before starting the engine, run the script **vccurl_replier.bat**. However, now the script window will need to be closed manually after closing the engine.

If you are on **Linux**/**MacOS**:
Before starting the engine, you need to run the **vccurl_replier.sh** script, and after closing the engine, you also need to close it manually.

The **vccurl_replier** script is required to provide interaction with **curl**

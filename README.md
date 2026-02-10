# shadps4-from-ps4

A tool that allows you to play games on shadps4, straight from your PS4.
Using this tool, you dont need to dump the whole game to another disk, but assets are streamed from your console (except for a few files, but still a rather big difference in total size). This works by creating a FTP connection between your system and your PS4.
> [!NOTE]
> Although not mandatory, it is recommended that your system is connected to the ps4 with an ethernet cable for speed.

## Requirements
1. A jailbroken PS4
2. A linux system

## Guide
1. Clone the repo.
2. Jailbreak your PS4 and start an FTP server.
3. Start one of your games.
4. Until the upstream project is fixed, download the custom [curlftpfs release](https://github.com/kalaposfos13/shadps4-from-ps4/releases/tag/curlftpfs) (see description as to why).
5. Create a mount point for your ps4: `sudo mkdir -p /mnt/ps4 && sudo chown $(whoami) /mnt/ps4`. The mountpoint can be whatever is more convenient to you.
6. Run `./run-current-game.sh`. On the first try you will get a message: `Please set your enviroment variables.`. Then run `nano .env` and fill in the details that are asked.

## Flags
- -c: Unmounts the overlayfs and ftp mounts, if they're mounted.
- -d: Run the script, but don't start the emulator.
- -b: Only mount and run the base game.

# shadps4-from-ps4

A tool that allows you to play games on shadps4, straight from your PS4.
Using this tool, you dont need to dump the whole game to another disk, but assets are streamed from your console (except for a few files, but still a rather big difference in total size). This works by creating a FTP connection between your system and your PS4.
> [!NOTE]
> Although not mandatory, it is recommended that your system is connected to the ps4 with an ethernet cable for reliability.

## Requirements
1. A jailbroken PS4
2. A linux system

## Guide
1. Jailbreak your PS4 (GoldHen recommended) and start the included FTP server
2. Start one of your games
3. Clone the project locally
4. Inside that project download [curlftpfs release](https://github.com/kalaposfos13/shadps4-from-ps4/releases/tag/curlftpfs)
5. Create a mount point for your ps4: `sudo mkdir -p /mnt/ps4`. In reality the point can be whatever is more convenient to you.\
Set the curlftpfs as executable: `chmod +x ./curlftpfs`. Then `./curlftpfs PS4_IP:PORT`. This will automatically create a filesystem for you.
7. Set the files as executables `chmod +x ./ftpminidump ./run-current-game.sh`
8. Run `./run-current-game.sh`
On the first try you will get a message: `Please set your enviroment variables.`. Then run `nano .env` and fill in the details that are asked.

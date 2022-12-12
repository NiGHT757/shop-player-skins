# shop-player-skins
Allow players to buy and set Server-Side skins on the server.

# Features:
sm_shop_reloadmodels - Reload plugin config. (This command will unregister and re-register all shop items from the config file without restarting the server or plugin.)

Rotating + glow preview model.

Set default models for **CT** and/or **T**.

Arms model will not be set if the client does not have default gloves equipped.

If the arms model or model specified in the config does not exist, it will be omitted from the shop registration.

Restrict the models to be bought or equipped by specifying **"flag" "flags desired"** eg: **"flags" "ab"**

# Requirements:
[[Shop] Core (Fork)](https://hlmod.ru/resources/shop-core-fork.284/) and [SourceMod](https://www.sourcemod.net/downloads.php?branch=stable) 1.11 or higher

[Directory Downloader](https://hlmod.ru/resources/directory-downloader.660/) or other plugin for downloading files.

[(OPTIONAL) - Fix Arms](https://hlmod.ru/resources/fix-arms.1740/) or other plugin for fix custom arms models.

# Instalation
1. Unpack and upload the files on the server.

# Preview 
![image](https://user-images.githubusercontent.com/86895149/206939405-0248b0ff-5d39-46bb-87d7-b1a8929572c1.png)

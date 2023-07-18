# ChRadium
> Note: This project is independent from blendOS.

The "Ch" stands for Chlorine, used to clean up pools. This script removes chromeOS and replaces it with a clean, Arch Linux ARM or blendOS system.

## What is this?

Arch Linux ARM, Ubuntu, Debian, and blendOS (unsupported for now) for unsupported ARM Chromebooks

> Note: For blendOS developers, this is different from blendOS Builder.

## Installing a distro

> Note: This script supports both glibc and musl based Linux distros.

The currently supported distros are Arch Linux ARM, Ubuntu, and Debian.

Clone the repository with ``` git clone https://github.com/aneeshlingala/ChRadium ```

Then, go into the ChRadium folder with ``` cd ChRadium ```

After that, run the main.sh script with root permissions.

For Sudo Users: ``` sudo bash chradium.sh ```

For Doas Users: ``` doas bash chradium.sh ```

For SU users: ``` su root ```, then, ``` bash chradium.sh ```

Now, there will be a prompt to select the distro to install.
Select your favorite distro and follow the prompts!


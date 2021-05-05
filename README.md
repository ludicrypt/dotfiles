# My dotfiles

Just the way I like 'em.

## Getcha' pull

1. Make sure everything is up to date

   ```shell
   sudo softwareupdate -i -a --restart
   ```

2. Install Xcode command line tools

   ```shell
   xcode-select --install
   ```

3. Reboot and repeat as needed

4. Run the bootstrap script, grab a beverage, sit back and relax.

   ```shell
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ludicrypt/dotfiles/working/bootstrap.sh)" 2>&1 | tee bootstrap.log
   ```

5. Reboot one last time for good measure.

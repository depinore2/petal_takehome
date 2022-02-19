# petal_takehome

## Getting Started ##
This uses terraform, nodejs, and a little bit of powershell.  Rather than assuming that you have this tooling available on your local machine, I decided to use a docker container that can be spun up in a VS Code session using the "Remote - Containers" extension.  

Please make sure you have [Visual Studio Code](https://code.visualstudio.com/) and [the aforementioned extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) installed.

Once that's done, follow these steps:
1. Open the Command Palette (`CTRL+Shift+P` on Linux and Windows, `Cmd+Shift+P` on macOS).
1. Select "Reopen and Rebuild in Container".
1. Once that's done building up, open the terminal.
1. Type `pwsh` to get a Powershell Core session started.
1. Run the initialization script: `./run.ps1`.
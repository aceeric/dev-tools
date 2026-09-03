# Dev Tools

This project contains scripting to create two VMs using KVM & libvirt. All VMs are intended to be Alma 10. (That's the only testing that's been done to date.)

Each directory below has a more detailed README.

## The `vscode-server` directory

This code creates a VM that is set up to run VS Code Remote SSH server. When you connect VS Code to it the first time, VS Code will download and install the VS Code SSH Server into the VM. But all the prerequisites are already there so it should simplify running VS Code remotely in the VM.

## The `devbox-alma10` directory

This code creates a VM configured as a dev box: installs VS Code, Golang, Kubectl, Terragrunt, and OpenTofu. (More tools can be added simply by dropping the install script into the `tools.d` directory.) The goal here is to create a VM that will be suitable for doing development that might raise the risk of introducing malware into your dev environment. For example, there have been recent reports of supply chain attacks in the tools supporting Agentic AI. This VM is intended to mitigate that.

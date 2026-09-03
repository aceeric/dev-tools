# VSCode Remote SSH Server VM

Creates an Alma 10 VM pre-configured to run VS Code Remote SSH server using
a hard-coded kickstart. When you create the VM you mount a directory from your
host file system. This enables VSCode Server running in the guest to read/write
files on your local file system (on the host.)

Here's how to use it:

## Download Alma 10

```
wget https://repo.almalinux.org/almalinux/10/isos/x86_64_v2/AlmaLinux-10.2-x86_64_v2-dvd.iso
```

## Create an SSH key

This key will be used to configure SSH access to the server for you and VSCode.

```
ssh-keygen -t ed25519 -N '' -f ./id_ed25519 <<<y
```

> Please note that any issues with SSH configuration will prevent VS Code from accessing the
> server. So Once the VM is provisioned - validate SSH access using the `coder` user name before
> trying to connect VS Code to the server.

## Create the VM

This assumes you downloaded Alma to _this_ directory:

```
./create-vm\
  --vm-name myvscode-server\
  --linux-iso-path ./AlmaLinux-10.2-x86_64_v2-dvd.iso\
  --os-variant almalinux10\
  --ssh-key ./id_ed25519.pub\
  --shared-dir $PWD
```

## Use it

### Get the VM's IP address

On the host: `virsh domifaddr myvscode-server`. Note the IP under the Address
column (strip the /24 suffix.)

### Install the Remote - SSH extension

In VS Code (the client, running on your host machine), install Microsoft's
'Remote - SSH' extension from the marketplace if you don't already have it.

### Update the custom.ssh.config file

Open `custom.ssh.config` in this directory and fill in the portions where
you see the prompts:

```
Host myvscode-server
  HostName <IP ADDRESS OF THE VM HERE>
  User coder
  IdentityFile <PATH TO THE GENERATED SSH PRIVATE KEY HERE>
  ForwardAgent yes
  StrictHostKeyChecking no
```

### Add custom config to VSCode

Open VSCode User Settings in JSON. Add:

```
  "remote.SSH.configFile": "/absolute/path/to/custom.ssh.config",
```

### Connect to the host

In VSCode on the host, click Remote Explorer in the left panel. You should see
`myvscode-server` if you preserved the name (or the new name if you changed it.)
On first connection, VS Code downloads its server component into the guest over the
SSH session and runs it under the `coder` account in `~/.vscode-server` on the
guest. The guest needs outbound internet.

Once connected, use File → Open Folder and select `/mnt/workspace` - that's the
`virtiofs`-mounted directory from `--shared-dir`. From here it behaves like a normal local
folder: editing, terminal, extensions, and git all run against files that physically
reside on your host.

## In the guest

In `/home/coder` you should see the downloaded VS Code SSH Server:

```
$ ls -l ~/.vsc*
total 33436
drwxr-xr-x 3 coder coder       74 Aug 27 20:00 cli
-rwxr-xr-x 1 coder coder 34235616 Aug 18 14:33 code-110a328ea54b42367b803ec53ee0bf52ef26b419
```

## Troubleshoot

You can access the host directly (without SSH) to troubleshoot:

```
virsh console myvscode-server
```

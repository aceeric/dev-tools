# Alma 10 Dev VM

Creates an Alma 10 dev VM, installing tools from the `tools.d` directory. The idea is to use this
machine for a dev sandbox whenever you're doing any development or experimentation that could expose
your desktop to malware. (E.g. Agentic AI.) The VM is set up with a full graphical environment.

The install setup creates two virtual monitors. More on that below.

Here's how to use it:

## Download Alma 10

```
wget https://repo.almalinux.org/almalinux/10/isos/x86_64_v2/AlmaLinux-10.2-x86_64_v2-dvd.iso
```

## Create the VM

This assumes you downloaded Alma to _this_ directory. The user account created in the VM is
`dev`. The `--tools-dir` arg enables installation of the tools in the specified directory -
in this case `tools.d` in this repo.

```
./create-vm\
  --vm-name alma10-dev\
  --linux-iso-path ./AlmaLinux-10.2-x86_64_v2-dvd.iso\
  --os-variant almalinux10\
  --host-mount-dir $PWD\
  --dev-password frobozz\
  --host-scripts-manifest ./devbox-utils.manifest\
  --bashrc-local ./devbox-bashrc-local\
  --tools-dir ./tools.d
```

> Note - the script uses `sshpass` to ssh to the VM using a password on the command line.

## Use the VM

Start the VM, then access the GUI. Note - the VM is created with dual monitors so the command below
creates two full-screen windows - one left monitor and one right:

```
virt-viewer --full-screen --attach alma10-dev
```

The only weirdness I've experienced so far is that when you drag a window in the VM from the left to
the right monitor. Gnome **in the VM** traps that and prevents it. So the way to drag between monitors
is to drag part pay, then re-grab in the target monitor and drag the rest of the way.

## SSH/scp

The guest runs `sshd`. It's already configured to mount a r/o host directory. If you ever need to
`scp` something **out** - or - `ssh` **in** then:

Get the VM IP address (example removes the `/nn` portion of the CIDR address):

```
vm=alma10-dev
ipaddr=$(virsh domifaddr $vm | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk '{print $4}')
ipaddr=$(echo "${ipaddr%/*}")
```

**SSH** (example uses `sshpass`):

```
ssh-keygen -R $ipaddr && sshpass -p frobozz ssh -o "StrictHostKeyChecking no" dev@$ipaddr
```

**SCP** (example uses `sshpass`):

```
sshpass -p frobozz scp dev@$ipaddr:.bashrc bashrc-from-vm
```

## DRI

DRI stands for Direct Rendering Infrastructure. It is a framework in Linux that lets programs
talk directly to the graphics hardware (GPU). DRI bypasses the display server: In older systems
programs had to send graphics data through the display server (like X11) to draw on the screen.
DRI allows programs to draw directly on the video hardware, which makes 3D games and graphics
run much faster. The `create-vm` script warns if `/dev/dri/renderD128` is missing, but you can
verify it yourself first:

```
$ ls /dev/dri/
```

Desired output:

```
by-path  card1  renderD128
```

In the `virt-install` script, `gl.rendernode=/dev/dri/renderD128` needs an actual
VirGL-capable GPU render node on your host - if your host is headless/cloud/no-iGPU,
or running an NVIDIA proprietary driver without the right DRI setup, this will fail
to start rather than degrade gracefully.

## Test `build-kickstart`

```
./build-kickstart\
  --template alma-devbox.ks.cfg\
  --password-hash $(openssl passwd -6 frobozz)\
  --host-scripts-manifest ./devbox-utils.manifest\
  --bashrc-local ./devbox-bashrc-local\
  --tools-dir ./tools.d
  --out ./ks.cfg
```

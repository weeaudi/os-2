sudo apt update
sudo apt install nasm gcc mtools qemu qemu-system-i386 xfce4 xfce4-goodies tightvncserver -y
vncserver
vncserver -kill :1
sudo cat vncconfig > ~/.vnc/xstartup
sudo cat watcompath > ~/.bashrc
sudo chmod +x ~/.vnc/xstartup
vncserver
cd ./noVNC-1.4.0
./utils/novnc_proxy --vnc localhost:5901
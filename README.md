[![GitHub Tag](https://github.com/ivan-danov/xcertcheck/actions/workflows/build_deb.yml/badge.svg)](https://github.com/ivan-danov/xcertcheck/releases)

# XCertCheck

SSL Certificate checker service

## Create deb package
make deb

## Or download latest release
curl -fsSL "$(curl -s "https://api.github.com/repos/ivan-danov/xcertcheck/releases/latest"|grep "browser_download_url.*deb"|cut -d ':' -f 2,3|tr -d \"|xargs)" -o ./xcertcheck.deb
sudo apt -qq install -y ./xcertcheck.deb
rm ./xcertcheck.deb

## Install deb package
apt install ./xcertcheck\_&lt;VERSION&gt;\_all.deb

## Use XCertCheck

### Config

create /etc/xcertcheck.conf file. example:<br/>
<br/>
DOMAINS=/etc/xcertcheck.list.txt<br/>
RECIPIENT=user@example.com<br/>
DAYS=7<br/>
XMAIL=msmtp<br/>
<br/>
create /etc/xcertcheck.list.txt file. example:<br/>
www.danov.pro:443<br/>
www.google.com:443<br/>
www.github.com:443<br/>
<br/>

### Start

sudo systemctl enable xcertcheck@daily.service<br/>
sudo systemctl enable xcertcheck-daily.timer<br/>

### Start from console

sudo systemctl start xcertcheck@daily.service<br/>

### Show timer status

sudo systemctl list-timers -all 'xcertcheck*'<br/>

### View log

journalctl -u xcertcheck@daily.service<br/>

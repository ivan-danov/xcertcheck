[![GitHub Tag](https://github.com/ivan-danov/xcertcheck/actions/workflows/build_deb.yml/badge.svg)](https://github.com/ivan-danov/xcertcheck/releases)

# XCertCheck

SSL Certificate checker service

## Create deb package
make deb

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

sudo systemctl enable xcertcheck@daily
sudo systemctl enable xcertcheck-daily.timer

### Start from console

sudo systemctl start xcertcheck@daily

### Show timer status

sudo systemctl list-timers -all 'xcertcheck*'

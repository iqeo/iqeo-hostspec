# Iqeo::Hostspec

[![Gem Version](https://badge.fury.io/rb/iqeo-hostspec.png)](http://badge.fury.io/rb/iqeo-hostspec)
[![Build Status](https://travis-ci.org/iqeo/iqeo-hostspec.png?branch=master)](https://travis-ci.org/iqeo/iqeo-hostspec)

A utility and Ruby library to generate lists of IP addresses from Nmap-style IP host specifications.
```
hostspec 1.0.0.1-3
10.0.0.1
10.0.0.2
10.0.0.3
```

In addition to expanding host specs to a list, a command may be executed for each IP address. See Program Usage below.

## Installation

Install a current version of Ruby from:

```
https://www.ruby-lang.org/en/installation/
```

Iqeo::Hostspec is packaged as a Ruby gem. To install, execute:

```
gem install iqeo-hostspec
```

To use the library in your own applications:

```ruby
require 'iqeo/hostspec'
```

## Program Usage

For help with usage, execute:

```
hostspec --help
```

```
Usage: hostspec [ options ] specs... [ [ -c / --cmd ] command ]

Prints all IP addresses for IP host specifications (see Specs:).
If specified, a command is executed for each IP address, with related values in environment variables (see Command:).

Specs:
  Nmap-style IP host specifications, multiple specs separated by spaces.
  Single host       : x.x.x.x or hostname
  Multiple hosts:
  - by mask length  : x.x.x.x/m or hostname/m
  - by octet values : x.x.x.a,b,c
  - by octet ranges : x.x.x.d-e
  Octet values and ranges may be combined or applied to any/multiple octets.
  Examples:
    hostname         : localhost      => 127.0.0.1
    hostname w/mask  : localhost/24   => 127.0.0.0  127.0.0.1 ... 127.0.0.254  127.0.0.255
    address          : 1.0.0.1        => 1.0.0.1
    address w/mask   : 2.0.0.1/24     => 2.0.0.0  2.0.0.1  ...  2.0.0.254  2.0.0.255
    address w/values : 3.0.0.10,20,30 => 3.0.0.10 3.0.0.20 3.0.0.30
    address w/ranges : 4.0.0.40-50    => 4.0.0.40 4.0.0.41 ...  4.0.0.49 4.0.0.50
    address w/combo  : 5.0.0.2,4-6,8  => 5.0.0.2  5.0.0.4  5.0.0.5  5.0.0.6  5.0.0.8
    multiple octets  : 6.1-2,3.4-5.6  => 6.1.4.6  6.1.5.6  6.2.4.6  6.2.5.6  6.3.4.6  6.3.5.6

Command:
  A command to execute for each IP address may be specified following the command switch ( -c / --cmd ).
  The command is executed in a separate shell for each IP address.
  Environment variables are provided with values for each IP address command execution.
  Quote these variables in the command to prevent substitution by the current shell.
    $HOSTSPEC_IP      : IP address
    $HOSTSPEC_MASK    : Mask (255.255.255.255 if a mask length was not specified)
    $HOSTSPEC_MASKLEN : Mask length (32 if a mask length was not specified)
    $HOSTSPEC_COUNT   : Count of IP addresses
    $HOSTSPEC_INDEX   : Index of IP address (from 1 to Count)
  Examples:
    Print IP addresses and mask length with index and count:
      hostspec 1.1.1.0/30 --cmd echo '$HOSTSPEC_INDEX' of '$HOSTSPECT_COUNT' : '$HOSTSPEC_IP/$HOSTSPEC_MASKLEN'
      ...
      1 of 4 : 1.1.1.0/255.255.255.252
      2 of 4 : 1.1.1.1/255.255.255.252
      3 of 4 : 1.1.1.2/255.255.255.252
      4 of 4 : 1.1.1.3/255.255.255.252
    Collect routing tables of all hosts on a network via ssh:
      hostspec 1.1.1.1-254 --cmd 'ssh me@$HOSTSPEC_IP route -n'
    Collect default web pages from all servers on a network via curl:
      hostspec 1.1.1.1-254 --cmd curl -o '$HOSTSPEC_IP.html' 'http://$HOSTSPEC_IP'
    Collect IP configuration info from multiple windows systems (run from a windows system):
      hostspec 1.1.1.1-254 --cmd psexec '\\%HOSTSPEC_IP%' ipconfig /all
    Collect IP configuration info from multiple windows systems (run from a linux system with kerberos):
      hostspec 1.1.1.1-254 --cmd winexe --kerberos yes //$(dig -x '$HOSTSPEC_IP' +short) ipconfig /all
    ...or any task that you would have to execute individually on multiple systems.

Options:
  -h / --help     : Display this helpful information
  -v / --version  : Display program version
```

## License

Licensed under GPLv3, see LICENSE.txt.


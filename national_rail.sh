#!/bin/bash
source ~/.bash_profile
chruby 2.3.1
cd ~/Dropbox/national_rail_notifier/ && ruby run.rb

#!/usr/bin/env python
#Copyright (C) 2009-2010 :
#    Gabes Jean, naparuba@gmail.com
#    Gerhard Lausser, Gerhard.Lausser@consol.de
#    Gregory Starck, g.starck@gmail.com
#    Hartmut Goebel, h.goebel@goebel-consult.de
#
#This file is part of Shinken.
#
#Shinken is free software: you can redistribute it and/or modify
#it under the terms of the GNU Affero General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#Shinken is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU Affero General Public License for more details.
#
#You should have received a copy of the GNU Affero General Public License
#along with Shinken.  If not, see <http://www.gnu.org/licenses/>.


def dark():
    r"""
                       .-.
                      |_:_|
                     /(_Y_)\
                    ( \/M\/ )
 '.               _.'-/'-'\-'._
   ':           _/.--'[[[[]'--.\_
     ':        /_'  : |::"| :  '.\
       ':     //   ./ |oUU| \.'  :\
         ':  _:'..' \_|___|_/ :   :|
           ':.  .'  |_[___]_|  :.':\
            [::\ |  :  | |  :   ; : \
             '-'   \/'.| |.' \  .;.' |
             |\_    \  '-'   :       |
             |  \    \ .:    :   |   |
             |   \    | '.   :    \  |
             /       \   :. .;       |
            /     |   |  :__/     :  \\
           |  |   |    \:   | \   |   ||
          /    \  : :  |:   /  |__|   /|
      snd |     : : :_/_|  /'._\  '--|_\
          /___.-/_|-'   \  \
                         '-'

"""
    print dark.__doc__


def get_coffee():
    r"""

                        (
                          )     (
                           ___...(-------)-....___
                       .-""       )    (          ""-.
                 .-'``'|-._             )         _.-|
                /  .--.|   `""---...........---""`   |
               /  /    |                             |
               |  |    |                             |
                \  \   |                             |
                 `\ `\ |                             |
                   `\ `|                             |
                   _/ /\                             /
                  (__/  \                           /
               _..---""` \                         /`""---.._
            .-'           \                       /          '-.
           :               `-.__             __.-'              :
           :                  ) ""---...---"" (                 :
            '._               `"--...___...--"`              _.'
          jgs \""--..__                              __..--""/
               '._     "'"----.....______.....----"'"     _.'
                  `""--..,,_____            _____,,..--""`
                                `"'"----"'"`


"""
    print get_coffee.__doc__



def episode_iv():
    hst = 'towel.blinkenlights.nl'

    from telnetlib import Telnet

    t = Telnet(hst)
    while True:
        buf = t.read_until('mesfesses', 0.1)
        print buf


def perdu():
    import urllib
    f = urllib.urlopen("http://www.perdu.com")
    print f.read()



def myip():
    import urllib
    f = urllib.urlopen("http://whatismyip.org/")
    print f.read()

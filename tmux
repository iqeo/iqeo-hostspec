#! /bin/bash

dir=$(pwd)
session=$(basename "$dir")

tmux rename-session "$session"
tmux rename-window shell

tmux new-window   -n vim -d
tmux send-keys    -t vim "cd ." C-m  
tmux send-keys    -t vim "vim ." C-m  

tmux new-window   -n rspec -d
tmux send-keys    -t rspec "cd ." C-m
tmux send-keys    -t rspec "rs" C-m

tmux new-window   -n irb -d
tmux send-keys    -t irb "cd ." C-m
tmux send-keys    -t irb "irb" C-m

#tmux new-window   -n rdoc -d
#tmux split-window -t rdoc -p 0
#tmux send-keys    -t rdoc.1 "cd ." C-m
#tmux send-keys    -t rdoc.1 "gem server" C-m
#tmux send-keys    -t rdoc.0 "cd ." C-m 
#tmux send-keys    -t rdoc.0 "sleep 10" C-m 
#tmux send-keys    -t rdoc.0 "links http://127.0.0.1:8808" C-m 

#tmux new-window   -n log -d
#tmux send-keys    -t log "cd ." C-m
#tmux send-keys    -t log "tail -f log/development.log" C-m

#tmux new-window   -n rails -d
#tmux send-keys    -t rails "cd ." C-m
#tmux send-keys    -t rails "rails server --binding=127.0.0.1" C-m

tmux swap-window  -s vim -t shell


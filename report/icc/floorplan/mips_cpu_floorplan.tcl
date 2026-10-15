###################################################################

# Created by write_floorplan on Thu Apr  2 12:56:21 2015

###################################################################
undo_config -disable

remove_die_area 

create_die_area  \
	-poly {	{0.000 0.000} {388.480 0.000} {388.480 385.920} {0.000 385.920} {0.000 0.000}} 
set oldSnapState [set_object_snap_type -enabled false]


set_object_snap_type -enabled $oldSnapState
undo_config -enable

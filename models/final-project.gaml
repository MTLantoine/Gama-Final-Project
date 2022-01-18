/**
* Name: finalproject
* Based on the internal empty template. 
* Author: Antoine MORTELIER & Louis DUTOIT
* Tags: 
*/


model finalproject

global {
	int nb_trees <- 50;
	geometry shape <- square(20 #km);
	float step <- 10#mn;	
	
	init {
		create tree number: nb_trees;
	}
}

species tree {
	float max_height <- 20.0;
	float tree_grow<- rnd(0.01);
	float size <- rnd(1.0, 2.0) max: max_height update: size + tree_grow;
	aspect default {
		draw pyramid(200 + size * 50) color: (size > 0) ? #green : #brown border: #black;	
	}
}

experiment TreeBdi type: gui {

	output {
		display map type: opengl {
			species tree ;
		}
	}
}

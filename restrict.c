#include <unistd.h>
#include <string.h>

//#define DEBUG

#ifdef DEBUG
	#include <stdio.h>
#endif

enum select {
	NONE,
	RSYNC,
	UNISON
};

#define UNISON_BIN "unison"
#define RSYNC_BIN "rsync"

int main(int argc, char *argv[]) {
#ifdef DEBUG
	for(int i = 0; i < argc; i++) {
		printf("arg[%d] = %s\n", i, argv[i]);
	}
#endif

	if(argc < 3)
		return -1;

	/**
	 * Paranoid af C code because exposed to server.
	 **/
	enum select selected = NONE;

	if(!strcmp(argv[1], UNISON_BIN))
		selected = UNISON;
	
	if(!strcmp(argv[1], RSYNC_BIN))
		selected = RSYNC;

	char *run = NULL;
	switch(selected) {
		case NONE:
		default:
			return -1;
			break;
		case RSYNC:
			run = RSYNC_BIN;
			break;
		case UNISON:
			run = UNISON_BIN;
			break;
	}

	// let 'er rip
	execvp(run, &argv[1]);
}


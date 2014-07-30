/*
 * A sample import program for the DB file system. 
 *
 * processes records from an ASCII text file, one record per line with the
 * or-bar (|) separating the fields, creating an APPGEN database file.  The
 * data fields are 1) a numeric customer number is the first part of a
 * multi-part key, 2) text (name) attribute one, 3) text (address) attribute
 * two, 4) number w/decimal attribute three, convert to implied decimal form
 * 5) date w/slashes (D2/) is second part of multi-part key, convert to
 * APPGEN date form 
 *
 * This program is intended to be a 'go-by', it should be modified to reflect
 * the actual data in your situation. 
 *
 * To compile the code, enter it in import.c in the 'appgen/src' directory and
 * make appropriate entries in the makefile. 
 *
 * Note that the program as presented is not very tolerant of input errors. 
 *
 */

# include <appgen.h>
# include <vm.h>
# include <db.h>

char **argvec; /* global copy of argument vector required by
 * some library functions */

/*
 * definitions for text record handling 
 */
char line[256]; /* big enough for largest record */
char dest[80];

extern char *fgets(); /* type must be declared for externals */
extern FILE *fopen();

int mvCount = 0;
int len = 0;

extern char *date_in(); /* from APPGEN library */
char key[100];

main(argc, argv)
	/* standard C program start-off */
	int argc;char *argv[]; {

	FILE *in_file; /* stdio file descriptor for text file with list of keys*/
	DB *dest_db; /* APPGEN database file */
	DB *src_db; /* source database file */

	int rec_cnt = 0; /* count the records */
	int i; /* general index */
	int k;
	int j;
	long last_sold;
	long last_recv;

	argvec = argv; /* initialize global argvec */

	if (argc != 3) { /* need exactly 2 arguments */
		/* error message */
		printf("usage: %s infile outfile \n", argv[0]);
		exit(1); /* non-zero convention for error exit */
	}

	/*
	 * Try to open input file first to simplify the error handling if it
	 * cannot be opened (it's easier to back out of than a dbopen).
	 */

	if (!(in_file = fopen(argv[1], "r"))) {
		perror(argv[1]); /* print the usual cryptic message */
		exit(1);
	}

	if ((dest_db = db_open(argv[2])) == (DB *) NULL ) {
		/* if the pointer is null ... couldn't open data base - error */
		perror(argv[2]);
		fclose(in_file);
		exit(1);
	} else {

		printf("file opened %s\n", argv[2]);
	}

	/*
	 * Now read all the data in the input file constructing and writing a
	 * record for each.
	 */

	while (fgets(line, sizeof(line), in_file) != NULL ) { /* read a line ... */
		/* record key is multi-part: item number * warehouse */

		sprintf(key, "%s", line);

		len = strlen(key); /* remove trailing newline if exist */
		if (key[len - 1] == '\n')
			key[len - 1] = '\0';

		if (db_read(dest_db, key, 1) != 0) { /* read the status file */
			printf("unable to read record\n");
			continue;
		} else {
			/* save controlling attribute (9) and dependents 10 - 13 */
			for (i = 1; extract(dest_db, 9, i, dest, 79) > 0; i += 1) {
				replace(dest_db, 300, i, dest);

				extract(dest_db, 10, i, dest, 79);
				replace(dest_db, 301, i, dest);

				extract(dest_db, 11, i, dest, 79);
				replace(dest_db, 302, i, dest);

				extract(dest_db, 12, i, dest, 79);
				replace(dest_db, 303, i, dest);

				extract(dest_db, 13, i, dest, 79);
				replace(dest_db, 304, i, dest);
				mvCount += 1;
			}
			/* erase and rewrite attribute 9 - 13 */

			*dest = '\0';
			replace(dest_db, 9, 0, dest);
			replace(dest_db, 10, 0, dest);
			replace(dest_db, 11, 0, dest);
			replace(dest_db, 12, 0, dest);
			replace(dest_db, 13, 0, dest);
			replace(dest_db, 305, 0, dest);        /* erase this location so we can store last sold date */
			replace(dest_db, 306, 0, dest);        /* erase this location so we can store last recv date */

			/* re-populate attributes 9 - 13 from the saved values */
			for (k = 1; extract(dest_db, 300, k, dest, 79) > 0; k += 1) {
				insert(dest_db, 9, k, dest);

				extract(dest_db, 301, k, dest, 79);
				replace(dest_db, 10, k, dest);

				extract(dest_db, 302, k, dest, 79);
				replace(dest_db, 11, k, dest);

				extract(dest_db, 303, k, dest, 79);
				replace(dest_db, 12, k, dest);

				extract(dest_db, 304, k, dest, 79);
				replace(dest_db, 13, k, dest);

			}
			*dest = '\0';
			for (j = 1; extract(dest_db, 18, j, dest, 79) > 0; j += 1) {
				last_sold = atol(dest);
				if (last_sold > 0) {
					extract(dest_db, 14, j, dest, 79);
					replace(dest_db, 305, 1,dest);
					last_sold = atol(dest);
					 break;
				}
			}
			*dest = '\0';
						for (j = 1; extract(dest_db, 15, j, dest, 79) > 0; j += 1) {
							last_recv = atol(dest);
							if (last_recv > 0) {
								extract(dest_db, 14, j, dest, 79);
								replace(dest_db, 306, 1,dest);
								last_recv = atol(dest);
								 break;
							}
						}

			/* increment record count */
			rec_cnt++;
			printf("item %s has %d multi values last sold %d  last recv %d\n", key, mvCount,last_sold,last_recv);
			mvCount = 0;

			/* db_write makes the replaces permanent */
			db_write(dest_db);

		} /* continue while loop until in_file exhausted */
	}
	/* Close the files */
	fclose(in_file);
	db_close(dest_db);

	printf("done!! %d records processed\n", rec_cnt);

	exit(0);
}


/****************************************************************************/
/*   - MAKEXCOE: SLC1657 EMBEDDED ROM GENERATOR FOR XILINX '.COE' FILES -   */
/*                                                                          */
/*  The MAKEXCOE.C utility converts a SLC1657 application software file		*/
/*  into a XILINX '.coe' file.  The '.coe' file is used to create ROMs for	*/
/*  the SLC1657 when it is located on a XILINX SPARTAN-II target FPGA.		*/
/*  The application software to be converted is assumed to be formatted		*/
/*  as an Intel HEX file.  It has been tested with the output from the		*/
/*  following software tools:												*/
/*																			*/
/*			B Knudsen Data:  CC5X 'C' compiler								*/
/*			Parallax:		 SPASM assembler	  							*/
/*																			*/
/*																			*/
/*																			*/
/*                        - SOFTWARE PORTABILITY -                    		*/
/*                                                                          */
/*  This software was originally complied under Turbo C++ 3.0 from Borland	*/
/*  International, Inc.  However, it was written with maximum adherance to	*/
/*  ANSI-C, and should work with most compilers.  							*/
/*																			*/
/*  In order to maximize re-usability, this (and related) software must     */
/*  operate across a wide variety of hardware platforms.  In order to main- */
/*  tain maximum portability among many 'C' compilers, it is recommended    */
/*  that the ANSI-C implementation be used throughout (ANSI/ISO 9899-1990). */
/*  Furthermore, the following variable types should be used whenever       */
/*  possible:                                                               */
/*                                                                          */
/*          Variable Type            Standard Nomenclature & Use            */
/*      ---------------------   ---------------------------------------     */
/*      char                    8-bit, unsigned                             */
/*      signed char             8-bit, signed                               */
/*                                                                          */
/*      unsigned short int      16-bit, unsigned                            */
/*      short int               16-bit, signed                              */
/*                                                                          */
/*      unsigned long int       32-bit, unsigned                            */
/*      long int                32-bit, signed                              */
/*                                                                          */
/*      double                  64-bit, IEEE floating point                 */
/*                                                                          */
/*                                                                          */
/*  Use of other types are discouraged because the ANSI standard does not   */
/*  highly regulate the variable types.  In fact, the standard does not     */
/*  require that any type be contrained to a specific size.  For example,   */
/*  the 'int' type is allowed to be any size as long as the size of         */
/*  char <= int <= long.  Many compilers choose int to be 16 or 32 bits.    */
/*                                                                          */
/*  To overcome this problem, all software and compilers should conform to  */
/*  the above guidelines.  If other types are used, it should be clearly    */
/*  stated in the banner comments where they are used.                      */
/*                                                                          */
/****************************************************************************/

/****************************************************************************/
/* License:         MAKEXCOE Utility                                        */
/*                  Copyright (C) 2003 Silicore Corporation                 */
/*                                                                          */
/*                  This library is free software; you can                  */
/*                  redistribute it and/or modify it under the terms        */
/*                  of the GNU Lesser General Public License version        */
/*                  2.1 as published by the Free Software Foundation.       */
/*                                                                          */
/*                  This library is distributed in the hope that it         */
/*                  will be useful, but WITHOUT ANY WARRANTY; without       */
/*                  even the implied warranty of MERCHANTABILITY or         */
/*                  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU          */
/*                  Lesser General Public License for more details.         */
/*                                                                          */
/*                  You should have received a copy of the GNU Lesser       */
/*                  General Public License along with this library;         */
/*                  if not, write to the Free Software Foundation,          */
/*                  Inc., 59 Temple Place, Suite 330, Boston, MA            */
/*                  02111-1307  USA                                         */
/*                                                                          */
/* Support:         Support for this software in the form of                */
/*                  maintenance, system integration, consulting and         */
/*                  training is available for a fee from Silicore           */
/*                  Corporation.  For more information please refer         */
/*                  to the Silicore web site at: www.silicore.net.          */
/*                                                                          */
/****************************************************************************/

/****************************************************************************/
/*                                                                          */
/*                           - Module History -                             */
/*                                                                          */
/*            Description                          Name / Date              */
/*  ---------------------------------   ----------------------------------  */
/*  Initial design complete:               WD Peterson / 22 MAY 2001        */
/*  Release under the LGPL license:        WD Peterson / 03 SEP 2003        */
/*                                                                          */
/****************************************************************************/

/****************************************************************************/
/*                         - Include File(s) -                        		*/
/****************************************************************************/

#include 			<stdlib.h>
#include            <stdio.h>
#include            <string.h>
#include            <stddef.h>
#include			<time.h>


/****************************************************************************/
/*                       - Constant Declaration(s) -                        */
/****************************************************************************/

#define             MAX_STRING                      128
#define             SOFTWARE_VERSION_NUMBER         "1.0"


/****************************************************************************/
/*                   - Internal Function Declarations -                     */
/****************************************************************************/


/****************************************************************************/
/*                     - Global Variable Definitions -                      */
/****************************************************************************/


/****************************************************************************/
/*                                                                          */
/*  Function:       main()                                                  */
/*                                                                          */
/*  Description:    Xilinx COE file conversion routine.						*/
/*																			*/
/****************************************************************************/

int main( int argc, char *argv[] )
{
int				address;
int				data;
char			input_filepath[MAX_STRING];
FILE   		   *input_file_pointer;
char			input_string[MAX_STRING];
unsigned short *input_data;
int				m;
int				n;
int				num_data_records;
char			output_filepath[MAX_STRING];
FILE   		   *output_file_pointer;
char			temp_string[10];


	/************************************************************************/
	/* Print the header to the screen.										*/
	/************************************************************************/

	printf( "\n" );
	printf( "SLC1657 MAKEXCOE, VER: %s\n", SOFTWARE_VERSION_NUMBER );


	/************************************************************************/
	/* Set variables indicated by the command line argument(s).             */
	/*																		*/
	/* Command line syntax:	makexcoe sourcefile.hex							*/
	/*																		*/
	/* First check the syntax of the command line arguments.				*/
	/************************************************************************/

	if( (argc < 2) || (argc > 4) )
	{
		printf( "\n" );
		printf( "Command line argument syntax error.\n" );
		printf( "Type 'makexcoe ?' for correct argument syntax.\n" );
		printf( "Aborting makexcoe.\n" );
		return( 0 );
	}

	if( (strcmp( argv[1], "USAGE" ) == 0)
			|| (strcmp( argv[1], "usage" ) == 0)
				|| (strcmp( argv[1], "HELP" ) == 0)
					|| (strcmp( argv[1], "help" ) == 0)
						|| (strcmp( argv[1], "?" ) == 0) )
	{
		printf( "\n" );
		printf( "Command line syntax: makexcoe sourcefile.hex\n" );
		printf( "\n" );
		printf( "Where:\n" );
		printf( "sourcefile.hex: Input (Intel Hex) file path.  Note that\n" );
		printf( "                the '.obj' filepath can also be used.\n" );
		return( 0 );
	}


	/************************************************************************/
	/* Read the (input) filepath and check that it has a file extension		*/
	/* for an Intel HEX file ('.hex' or '.obj').							*/
	/************************************************************************/

	strncpy( input_filepath, argv[1], MAX_STRING );

	input_filepath[MAX_STRING - 1] = '\0';

	if( strlen( input_filepath ) == (MAX_STRING - 1) )
	{
		printf( "Input filepath is too long.\n" );
		printf( "Type 'makexcoe ?' for correct argument syntax\n" );
		printf( "Aborting makexcoe.\n" );
		return( 0 );
	}

	n = strlen( input_filepath ) - 1;
	while( input_filepath[n] != '.' )
	{
		if( n < 1 )
		{
			printf( "Input filepath error.\n" );
			printf( "Type 'makexcoe ?' for correct argument syntax\n" );
			printf( "Aborting makexcoe.\n" );
			return( 0 );
		}

		--n;
	}

	if( ( (input_filepath[n+1] != 'h') && (input_filepath[n+1] != 'H') )
		|| ( (input_filepath[n+2] != 'e') && (input_filepath[n+2] != 'E') )
			|| ( (input_filepath[n+3] != 'x') && (input_filepath[n+3] != 'X') )
				|| ( input_filepath[n+4] != '\0') )
	{
		if( ( (input_filepath[n+1] != 'o') && (input_filepath[n+1] != 'O') )
			|| ( (input_filepath[n+2] != 'b') && (input_filepath[n+2] != 'B') )
				|| ( (input_filepath[n+3] != 'j') && (input_filepath[n+3] != 'J') )
					|| ( input_filepath[n+4] != '\0') )
		{
			printf( "Input filename extension error (not '.hex' or '.obj').\n" );
			printf( "Type 'makexcoe ?' for correct argument syntax\n" );
			printf( "Aborting makexcoe.\n" );
			return( 0 );
		}
	}


	/************************************************************************/
	/* Create the output filepath name with a '.coe' extension.				*/
	/************************************************************************/

	strncpy( output_filepath, input_filepath, MAX_STRING );

	output_filepath[n+1] = 'c';
	output_filepath[n+2] = 'o';
	output_filepath[n+3] = 'e';
	output_filepath[n+4] = '\0';


	/************************************************************************/
	/*  Flush all I/O buffers.                                              */
	/************************************************************************/

	fflush( NULL );


	/************************************************************************/
	/* Allocate some memory for the data.  After reading the data from the	*/
	/* input file, it is stored in this space.  That's because the '.coe' 	*/
	/* initialization file requires contiguous memory initialization.  		*/
	/* Since an Intel HEX formatted file does not necessarily provide data	*/
	/* in a contiguous manner, it is first loaded into this data space.		*/
	/*																		*/
	/* The 'C' MALLOC() function is used to allocate memory.  While this	*/
	/* function automatically clears this memory to zero, it is re-cleared	*/
	/* by this function.  That's because the user may wish to initialize	*/
	/* this memory to a value other than zero (e.g. a jump instruction).	*/
	/************************************************************************/

	input_data = (unsigned short *) malloc( 0x0800 * sizeof(unsigned short) );

	if( !input_data)
	{
		printf( "ERROR: The operating system would not allocate 2K words of\n" );
		printf( "temporary storage in memory.\n" );
		printf( "Aborting makexcoe.\n" );
		return( 0 );
	}

	for( n = 0; n < 0x0800; n++ )
	{
		*(input_data + n) = 0x0000;
	}


	/************************************************************************/
	/* Open the input file.													*/
	/************************************************************************/

	if( (input_file_pointer = fopen( input_filepath, "r" )) == NULL )
	{
		printf( "\n" );
		printf( "ERROR: Couldn't open %s\n", input_filepath );
		printf( "Aborting makexcoe.\n" );
		fclose( input_file_pointer );
		return( 0 );
	}

	rewind( input_file_pointer );


	/************************************************************************/
	/* Read the data, convert it and save it to the database.				*/
	/************************************************************************/

	while( fscanf( input_file_pointer, "%s", &input_string ) != EOF )
	{
		n = 0;

		/********************************************************************/
		/* Verify that the first symbol is a ':'.							*/
		/********************************************************************/

		if( input_string[n++] != ':' )
		{
			printf( "\n" );
			printf( "ERROR: Unusual file format character found in input file: %s\n", input_filepath );
			printf( "Expected ':', but read '%c'.\n", input_string[n-1] );
			printf( "Aborting makexcoe.\n" );
			fclose( input_file_pointer );
			return( 0 );
		}


		/********************************************************************/
		/* Obtain the number of data records on the current line.			*/
		/********************************************************************/

		temp_string[0] = input_string[n++];
		temp_string[1] = input_string[n++];
		temp_string[2] = '\0';

		sscanf( temp_string, "%X", &num_data_records );


		/********************************************************************/
		/* Read the starting address of the line.							*/
		/********************************************************************/

		temp_string[0] = input_string[n++];
		temp_string[1] = input_string[n++];
		temp_string[2] = input_string[n++];
		temp_string[3] = input_string[n++];
		temp_string[4] = '\0';

		sscanf( temp_string, "%X", &address );


		/********************************************************************/
		/* Divide the byte address by two to get the instruction address.	*/
		/********************************************************************/

		address = address / 2;


		/********************************************************************/
		/* Ignore the next two characters in the line.						*/
		/********************************************************************/

		n = n + 2;


		/********************************************************************/
		/* Scan in the data from the line.									*/
		/********************************************************************/

		while( num_data_records > 0 )
		{
			/****************************************************************/
			/* Read the next instruction.									*/
			/****************************************************************/

			temp_string[0] = input_string[n+2];
			temp_string[1] = input_string[n+3];
			temp_string[2] = input_string[n+0];
			temp_string[3] = input_string[n+1];
			temp_string[4] = '\0';

			n = n + 4;

			sscanf( temp_string, "%X", &data );


			/****************************************************************/
			/* Verify that the instruction address is legitimate.  This has */
			/* the effect of stripping out the special configuration bits 	*/
			/* can be used with the Microchip implementation of the PIC		*/
			/* processor.													*/
			/****************************************************************/

			if( (address >= 0) && (address <= 0x07FF) )
			{
				/************************************************************/
				/* Print out the current address and instruction word. 		*/
				/************************************************************/

				printf ( "\r" );
				printf ( "ADDR: 0x%03X, INST: 0x%03X", address, data );


				/************************************************************/
				/* Save the data in the data array.							*/
				/************************************************************/

				*(input_data + address) = data;

			}

			num_data_records = num_data_records - 2;
			address++;
		}
	}


	/************************************************************************/
	/* We're done with the input file, so close it.							*/
	/************************************************************************/

	fclose( input_file_pointer );


	/************************************************************************/
	/* Open the output file.													*/
	/************************************************************************/

	if( (output_file_pointer = fopen( output_filepath, "w" )) == NULL )
	{
		printf( "\n" );
		printf( "ERROR: Couldn't open %s\n", output_filepath );
		printf( "Aborting makexcoe.\n" );
		fclose( output_file_pointer );
		return( 0 );
	}

	rewind( output_file_pointer );


	/************************************************************************/
	/* Put the header on the output file.									*/
	/************************************************************************/

	fprintf( output_file_pointer, "MEMORY_INITIALIZATION_RADIX=16;\n" );
	fprintf( output_file_pointer, "MEMORY_INITIALIZATION_VECTOR=\n" );


	/************************************************************************/
	/* Format and save the data to the output (.coe) file.					*/
	/************************************************************************/

	for( n = 0; n < 0x0800; n++ )
	{
		if( n == 0 )
		{
			fprintf( output_file_pointer,    "%03X", (int) *(input_data + n) );
		}
		else
		{
			fprintf( output_file_pointer, ",\n%03X", (int) *(input_data + n) );
		}
	}

	fprintf( output_file_pointer, ";\n" );


	/************************************************************************/
	/*	Conversion complete.  Cleanup and exit.  							*/
	/************************************************************************/

	fclose( output_file_pointer );

	printf( "\r" );
	printf( "Conversion complete.        \n" );

	return( 0 );
}


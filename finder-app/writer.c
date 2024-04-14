/**
* @file writer.c
* @description Solution for assignment 2 in the course "Linux System Programming and Introduction to Buildroot"
* @author Joe Castrejon 
* @date 
*/ 

#include <unistd.h>
#include <syslog.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char* argv[]){
	
	if (argc != 3){
		printf("ERROR: One or more parameters are missing.\n");
		syslog(LOG_ERR,"[ERROR] One or more parameters are missing");
		exit(1);	
	}
	
	openlog(NULL,LOG_PID,LOG_USER);	
	const char* writeFile = argv[1];
	const char* writeString = argv[2];

	int fd = open(writeFile, O_CREAT|O_RDWR|O_TRUNC, S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH);
		
	if(fd == -1){
		printf("ERROR: Could not create file \"%s\".\n",writeFile);
		syslog(LOG_ERR, "[ERROR] Could not create file \"%s\"", writeFile );
		closelog();
		exit(1);
	}

	int status = write(fd,writeString,sizeof(char)*strlen(writeString));
	syslog(LOG_DEBUG, "Writing \"%s\" to \"%s\"", writeString, writeFile);
		
	if(status == -1){
		printf("ERROR: Could not write to file \"%s\".\n", writeFile);
		syslog(LOG_ERR, "[ERROR] Could not write to file \"%s\"", writeFile);
		closelog();
		exit(1);
	}

	closelog();
	exit(0);		
}

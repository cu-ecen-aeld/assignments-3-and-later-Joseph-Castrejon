#include "systemcalls.h"
#include <sys/types.h> 
#include <sys/wait.h>
#include <fcntl.h>


/**
 * @param cmd the command to execute with system()
 * @return true if the command in @param cmd was executed
 *   successfully using the system() call, false if an error occurred,
 *   either in invocation of the system() call, or if a non-zero return
 *   value was returned by the command issued in @param cmd.
*/
bool do_system(const char *cmd)
{

	/*
	 * TODO  add your code here
	 *  Call the system() function with the command set in the cmd
	 *   and return a boolean true if the system() call completed with success
	 *   or false() if it returned a failure
	*/
	    
    	int status = system(cmd);
	
	/* 'cmd' resulted in non-zero exit */
	if(status != 0){	
		return false;
	}   	
     
	return true;
}

/**
* @param count -The numbers of variables passed to the function. The variables are command to execute.
*   followed by arguments to pass to the command
*   Since exec() does not perform path expansion, the command to execute needs
*   to be an absolute path.
* @param ... - A list of 1 or more arguments after the @param count argument.
*   The first is always the full path to the command to execute with execv()
*   The remaining arguments are a list of arguments to pass to the command in execv()
* @return true if the command @param ... with arguments @param arguments were executed successfully
*   using the execv() call, false if an error occurred, either in invocation of the
*   fork, waitpid, or execv() command, or if a non-zero return value was returned
*   by the command issued in @param arguments with the specified arguments.
*/

bool do_exec(int count, ...)
{
	va_list args;
	va_start(args, count);
	char * command[count+1];
	int i;

	for(i=0; i<count; i++){
		command[i] = va_arg(args, char *);
	}

	command[count] = NULL;
	// this line is to avoid a compile warning before your implementation is complete
	// and may be removed
	command[count] = command[count];

	/*
	* TODO:
	*   Execute a system command by calling fork, execv(),
	*   and wait instead of system (see LSP page 161).
	*   Use the command[0] as the full path to the command to execute
	*   (first argument to execv), and use the remaining arguments
	*   as second argument to the execv() command.
	*
	*/

	pid_t process = fork();
	bool execStatus = true;
	
	if(process == -1){
		/* Call to fork was unsucessful. */
		perror("ERROR");
		execStatus = false;
	}else if(!process){
		
		/* New child process created, execute new command.*/
		int status = execv(command[0], command);
		exit(status);
	}
	else{
		/*In parent, waiting for result.*/
		int status = 0;
		
		if(waitpid(process, &status, 0) == -1){
			execStatus = false;
		}
	}

	va_end(args);

	return execStatus;
}

/**
* @param outputfile - The full path to the file to write with command output.
*   This file will be closed at completion of the function call.
* All other parameters, see do_exec above
*/
bool do_exec_redirect(const char *outputfile, int count, ...)
{
	    va_list args;
	    va_start(args, count);
	    char * command[count+1];
	    int i;
	    for(i=0; i<count; i++)
	    {
		command[i] = va_arg(args, char *);
	    }
	    command[count] = NULL;
	    // this line is to avoid a compile warning before your implementation is complete
	    // and may be removed
	    command[count] = command[count];


	/*
	 * TODO
	 *   Call execv, but first using https://stackoverflow.com/a/13784315/1446624 as a reference,
	 *   redirect standard out to a file specified by outputfile.
	 *   The rest of the behaviour is same as do_exec()
	 *
	*/
	pid_t child_pid;
	bool execStatus = true;
	int status = 0;
	int fd = open(outputfile, O_WRONLY|O_TRUNC|O_CREAT, 0644);

	if(fd < 0){
		perror("open");
		abort();
	}

	switch(child_pid = fork() )
	{
		case -1:
	    		perror("fork");
			execStatus = false;
			break;
		case 0:
	    		if(dup2(fd,1) < 0){
				perror("dup2");
				abort();
			}
			close(fd);
			execv(command[0], command);
			perror("execv"); // This should never be reached.
			abort();
		default:
			
			waitpid(child_pid, &status, 0);
			execStatus = false;
			close(fd);
			break;
	}

	va_end(args);

	return execStatus;
}

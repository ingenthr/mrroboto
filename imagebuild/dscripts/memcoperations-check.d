#!/usr/sbin/dtrace -Zqs
/*
 * Show aggregated operations on a 1 second interval.  Determine if the 
 * operation was successful or unsuccessful by looking for the thread 
 * local after the operation has been handled.
 *
 */

memcached*::command-*
/ arg3 != -1 /
{
  @operations["success", probename] = count();
  /* seems to be a bug here, trond thinks it's in the macro... will try to 
   * fix
   */
  printf("key is %s, length is %d\n", copyinstr(arg1), arg3);
}

memcached*::command-*
/ arg3 == -1 /
{
  @operations["failed", probename] = count();
  printf("key is %s, length is %d\n", copyinstr(arg1), arg3);
}



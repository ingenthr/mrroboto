#!/usr/sbin/dtrace -Zqs
/*
 * show memcached keys as they're retrieved via either an ascii
 * or binary get operation
 */

memcached*::command-get
/ (signed int) arg3 != -1 /
{
  printf("get %s, FOUND KEY\n", copyinstr(arg1, arg2));
}

memcached*::command-get
/ (signed int) arg3 == -1 /
{
  printf("get %s, NOT FOUND\n", copyinstr(arg1, arg2));
}


memcached*::command-add
/ (signed int) arg3 != -1 /
{
  printf("add %s, FOUND KEY\n", copyinstr(arg1, arg2));
}

memcached*::command-add
/ (signed int) arg3 == -1 /
{
  printf("add %s, NOT FOUND\n", copyinstr(arg1, arg2));
}

memcached*::command-replace
/ (signed int) arg3 != -1 /
{ 
  printf("replace %s, FOUND KEY\n", copyinstr(arg1, arg2));
}

memcached*::command-replace 
/ (signed int) arg3 == -1 /
{ 
  printf("replace %s, NOT FOUND\n", copyinstr(arg1, arg2));
}

memcached*::command-set
/ (signed int) arg3 != -1 /
{ 
  printf("set %s, FOUND KEY, STORED\n", copyinstr(arg1, arg2));
}

memcached*::command-set
/ (signed int) arg3 == -1 /
{ 
  printf("set %s, NOT FOUND, STORED\n", copyinstr(arg1, arg2));
}

memcached*::command-incr
{
  printf("incr %s, FOUND KEY, %d\n", copyinstr(arg1, arg2), arg3);
}

memcached*::command-decr
{ 
  printf("decr %s, FOUND KEY, %d\n", copyinstr(arg1, arg2), arg3);
}

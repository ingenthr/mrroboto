#!/usr/sbin/dtrace -Zqs
/*
 * show memcached keys as they're retrieved via either an ascii
 * or binary get operation
 */

memcached*::command-get
{
  printf("%s\n", copyinstr(arg1));
}


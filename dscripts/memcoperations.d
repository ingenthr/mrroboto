#!/usr/sbin/dtrace -Zs
/*
 * Show aggregated operations on a 1 second interval.
 *
 */

BEGIN
{
  start = timestamp;
}

memcached*::command-*
{
  @ops[probename] = count();
}

memcached*::command-*
/ (signed int) arg3 == -1 /
{
  @opsnotfound[probename] = count();
}

profile:::tick-1sec
{
  printf("BEGIN\n");
  normalize(@ops, (timestamp - start) / 1000000000);
  printa(@ops);
  normalize(@opsnotfound, (timestamp - start) / 1000000000);
  printa(@opsnotfound);
  printf("END\n");
  clear(@ops);
  clear(@opsnotfound);
}


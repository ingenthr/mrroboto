#!/usr/sbin/dtrace -Zqs
/*
 * Show aggregated operations on a 1 second interval.
 *
 */

memcached*::command-*
{
  @operations[probename] = count();
}


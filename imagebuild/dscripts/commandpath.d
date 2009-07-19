#!/usr/sbin/dtrace -Zs
/*
 * Show the flow through memcached with the next operation. 
 *
 * This is mostly used to figure out what else to poke later when hunting
 * certain kinds of operations.
 * 
 * Requires the pid as an argument
 *
 */
#pragma D option flowindent

memcached*::process-command-start
{
  self->traceme = 1;
}

pid$1:::entry,
pid$1:::return
/ self->traceme /
{
}


memcached*::process-command-end
/ self->traceme /
{
  self->traceme = 0;
  exit(0)
}

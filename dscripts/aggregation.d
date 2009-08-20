#!/usr/sbin/dtrace -Zqs

BEGIN
{
  start = timestamp;
}

memcached*::command-get
{
        @hotfound[copyinstr(arg1, arg2)] = count();
}

memcached*::command-set
{
        @hotfound[copyinstr(arg1, arg2)] = count();
}

memcached*::command-add
{
        @hotfound[copyinstr(arg1, arg2)] = count();
}

memcached*::command-replace
{
        @hotfound[copyinstr(arg1, arg2)] = count();
}

memcached*::command-prepend
{
        @hotfound[copyinstr(arg1, arg2)] = count();
}

memcached*::command-append
{
        @hotfound[copyinstr(arg1, arg2)] = count();
}

memcached*::command-cas
{
        @hotfound[copyinstr(arg1, arg2)] = count();
}

memcached*::command-delete
{
        @hotfound[copyinstr(arg1, arg2)] = count();
}

memcached*::command-get
/ (signed int)arg3 == -1 /
{
        @hotmissing[copyinstr(arg1, arg2)] = count();
}

memcached*::command-set
/ (signed int)arg3 == -1 /
{
        @hotmissing[copyinstr(arg1, arg2)] = count();
}

memcached*::command-add
/ (signed int)arg3 == -1 /
{
        @hotmissing[copyinstr(arg1, arg2)] = count();
}

memcached*::command-replace
/ (signed int)arg3 == -1 /
{
        @hotmissing[copyinstr(arg1, arg2)] = count();
}

memcached*::command-prepend
/ (signed int)arg3 == -1 /
{
        @hotmissing[copyinstr(arg1, arg2)] = count();
}

memcached*::command-append
/ (signed int)arg3 == -1 /
{
        @hotmissing[copyinstr(arg1, arg2)] = count();
}

memcached*::command-cas
/ (signed int)arg3 == -1 /
{
        @hotmissing[copyinstr(arg1, arg2)] = count();
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

profile:::tick-3sec
{
  trunc(@hotfound, 20);
  trunc(@hotmissing, 20);
  normalize(@hotfound, (timestamp - start) / 1000000000);
  normalize(@hotmissing, (timestamp - start) / 1000000000);
  normalize(@ops, (timestamp - start) / 1000000000);
  normalize(@opsnotfound, (timestamp - start) / 1000000000);

  printf("BEGIN\n");
  printf("\nhotfound");
  printa(@hotfound);
  printf("\nhotmissing");
  printa(@hotmissing);
  printf("\nops");
  printa(@ops);
  printf("\nopsnotfound");
  printa(@opsnotfound);
  printf("END\n");

  clear(@hotfound);
  clear(@hotmissing);
  clear(@ops);
  clear(@opsnotfound);
  start = timestamp;
}

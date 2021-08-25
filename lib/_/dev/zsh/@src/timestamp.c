#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int
main(int argc, char **argv)
{
struct stat info;
struct stat info2;
int failed = 0;

if (argc == 1)
   {
   printf("%d\n", time(0));
   }

else if (argc == 2)
   {
   if (!stat(argv[1], &info))
      {
      printf("%d\n", info.st_mtime);
        /*
      printf("a: %d\n", info.st_atime);
      printf("c: %d\n", info.st_ctime);
        */
      }
   else
      printf("Could not stat: %s\n", argv[1]);
   }

else if (argc == 3)
   {
   if (  (failed = 1, !stat(argv[1], &info)) &&
      (failed = 2, !stat(argv[2], &info2)))
      {
      return (info.st_mtime == info2.st_mtime) ? 0 : 1;
      }
   else
      printf("Could not stat: %s\n", argv[failed]);
   }
else
   {
   fprintf(stderr, "%s: no filename provided\n");
   exit(1);
   }


return 0;
}
